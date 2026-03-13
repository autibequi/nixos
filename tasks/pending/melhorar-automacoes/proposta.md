# Proposta V2: Melhorias de Automação do Claudinho

> Atualização da proposta anterior. Itens já implementados estão marcados.

## Status da V1

| # | Melhoria | Status |
|---|----------|--------|
| 3 | `clau-new` template | ✅ Implementado |
| 1-2, 4-14 | Demais itens | Pendentes |

---

## Prioridade Alta (maior valor / menor esforço)

### 1. Runner: capturar output das execuções
**O que:** Salvar stdout/stderr do Claude em `.ephemeral/notes/<task>/last-output.log` (além do `.result`).
**Por que:** Quando uma task falha, não há como debugar — só temos `fail:1` no histórico. O log `logs-host-readonly` falhou e ninguém sabe por quê.
**Esforço:** Baixo — adicionar `| tee` no comando do runner.
```bash
OUTPUT_LOG="$CONTEXT_DIR/last-output.log"
if timeout "$TIMEOUT" claude ... 2>&1 | tee "$OUTPUT_LOG"; then
```

### 2. Runner: loop multi-tarefa por execução
**O que:** Processar todas as pending + 1 recurring por invocação, em vez de sair após 1 tarefa.
**Por que:** Com 4 pending na fila (como agora), leva 4 horas pra limpar. Com loop, limpa em ~80min.
**Esforço:** Baixo — envolver o bloco pick+execute num `while true` com break quando não houver mais tasks.
**Nota:** A task `paralelizar-trabalho` já investiga paralelismo real. Este item é o quick-win sequencial.

### 3. Runner: orphan reap não respeita source
**O que:** Linha 48 do runner manda orphans sempre pra `pending/`, mesmo que a task seja recurring.
**Por que:** Uma recurring que crashou sem lock é movida pra `pending/` e vira one-shot — perde a imortalidade.
**Esforço:** Baixo — checar se a task tem padrão de recurring (ou guardar source no lock antes do crash).
```bash
# Fix: checar se existe em recurring/ antes de devolver
if [ -d "$TASKS/recurring/$name" ] 2>/dev/null; then
  # já existe cópia em recurring, só remove a orphan
  rm -rf "$dir"
else
  # tentar detectar se era recurring pelo CLAUDE.md (auto-evolução = recurring)
  if grep -q "Auto-evolução" "$dir/CLAUDE.md" 2>/dev/null; then
    mv "$dir" "$TASKS/recurring/$name"
  else
    mv "$dir" "$TASKS/pending/$name"
  fi
fi
```

### 4. Makefile: `clau-status` bugado com `\n`
**O que:** O target `clau-status` usa `@echo "\n=== ..."` — o `\n` não é interpretado por `echo` padrão no bash (só com `-e`).
**Por que:** Output fica com `\n` literal em vez de quebra de linha. Dificulta leitura.
**Esforço:** Baixo — trocar `\n` por `@echo ""` + `@echo "=== ..."` separados.

### 5. clau-status: mostrar contexto rico
**O que:** Além do nome, mostrar: status da última run, duração, e primeira linha do objetivo.
**Por que:** `ls -1` é inútil — preciso abrir cada pasta pra saber o que é.
**Esforço:** Baixo — ler `historico.log` e `CLAUDE.md` de cada task.

### 6. Runner: notificação pós-execução
**O que:** `notify-send` no host quando task termina (container já tem Wayland socket).
**Por que:** Tasks rodam silenciosas. Sem notificação, só descobre resultado com `make clau-status`.
**Esforço:** Baixo — 1 linha no final do runner. Instalar `libnotify` no Dockerfile ou usar `wl-copy` como workaround.

---

## Prioridade Média

### 7. Dockerfile: layer caching + versionamento
**O que:** (a) Separar `nix profile install` em 2+ layers (estáveis vs voláteis). (b) Pinar versão do `@anthropic-ai/claude-code`.
**Por que:** Qualquer mudança no bloco `nix profile install` invalida TODO o cache. E `npm install -g` sem versão pode quebrar builds.
**Esforço:** Médio.
```dockerfile
# Layer 1: ferramentas estáveis
RUN nix profile install nixpkgs#jq nixpkgs#python3 nixpkgs#nodejs nixpkgs#wl-clipboard
# Layer 2: ferramentas que atualizam mais
RUN nix profile install nixpkgs#yt-dlp nixpkgs#ffmpeg nixpkgs#sox
# Pinar Claude Code
RUN npm install -g @anthropic-ai/claude-code@0.2.x
```

### 8. docker-compose: healthcheck
**O que:** Adicionar `healthcheck` ao serviço sandbox.
**Por que:** `docker compose up -d` retorna OK mesmo se o container crashar logo depois. Um healthcheck permite `--wait`.
**Esforço:** Baixo-médio.
```yaml
healthcheck:
  test: ["CMD", "claude", "--version"]
  interval: 30s
  timeout: 10s
  retries: 3
```

### 9. Stow: detecção de drift
**O que:** Target `make stow-diff` que compara `stow/` com `$HOME`, mostrando divergências.
**Por que:** Apps reescrevem configs (ex: Zed atualiza settings.json). Sem detecção, o stow fica desatualizado.
**Esforço:** Médio.

### 10. Runner: retry automático para tasks falhadas
**O que:** Campo `max_retries: N` no CLAUDE.md (ou arquivo `.meta`). Runner requeue em vez de mover pra `failed/` se ainda tem retries.
**Por que:** `logs-host-readonly` falhou 1x e morreu. Poderia ter tentado de novo.
**Esforço:** Médio — precisa persistir contagem de tentativas.

### 11. Makefile: target `clau-logs`
**O que:** `make clau-logs name=<task>` que mostra o último output + histórico de uma task específica.
**Por que:** Complementa a melhoria #1. Com output capturado, precisa de uma forma rápida de ler.
**Esforço:** Baixo.
```makefile
clau-logs:
	@[ -n "$(name)" ] || (echo "Uso: make clau-logs name=minha-tarefa" && exit 1)
	@echo "=== Histórico ===" && tail -20 .ephemeral/notes/$(name)/historico.log 2>/dev/null || echo "(sem histórico)"
	@echo "\n=== Último output ===" && tail -50 .ephemeral/notes/$(name)/last-output.log 2>/dev/null || echo "(sem output)"
```

---

## Prioridade Baixa

### 12. Usage: formato inconsistente no JSONL
**O que:** A primeira entrada do `2026-03.jsonl` não tem campos `status` e `type`. Normalizar.
**Por que:** `make usage` com `jq` pode quebrar se campos são opcionais.
**Esforço:** Baixo — já foi corrigido no runner, só precisa limpar dados antigos ou tornar o jq tolerante.

### 13. Tarefas: prioridade
**O que:** Suporte a `priority: high|normal|low` no CLAUDE.md. Runner processa high primeiro.
**Por que:** FIFO puro. Uma tarefa urgente espera todas as anteriores.
**Esforço:** Médio.

### 14. Tarefas: dependências
**O que:** Campo `depends_on` para criar pipelines.
**Por que:** Permitiria "gera migration → atualiza handler → testa".
**Esforço:** Alto.

### 15. docker-compose: `userns_mode: keep-id` é flag Podman
**O que:** Essa diretiva não existe no Docker padrão (só Podman). Se rodar com Docker puro, dá warning/erro.
**Por que:** Portabilidade. Se o setup mudar de Podman pra Docker, quebra silenciosamente.
**Esforço:** Baixo — documentar que requer Podman, ou usar `user: "1000:1000"` como fallback Docker.

---

## Resumo

| # | Melhoria | Esforço | Impacto |
|---|----------|---------|---------|
| 1 | Capturar output do runner | Baixo | **Alto** |
| 2 | Loop multi-tarefa | Baixo | **Alto** |
| 3 | Fix orphan reap (recurring) | Baixo | **Alto** |
| 4 | Fix `\n` no clau-status | Baixo | Médio |
| 5 | clau-status com contexto | Baixo | Médio |
| 6 | Notificação pós-tarefa | Baixo | Médio |
| 7 | Dockerfile layers + pin | Médio | Médio |
| 8 | Healthcheck container | Baixo-Médio | Médio |
| 9 | Stow drift detection | Médio | Médio |
| 10 | Retry automático | Médio | Médio |
| 11 | `clau-logs` target | Baixo | Médio |
| 12 | Fix JSONL inconsistente | Baixo | Baixo |
| 13 | Prioridade de tasks | Médio | Baixo |
| 14 | Dependências de tasks | Alto | Baixo |
| 15 | Documentar Podman req | Baixo | Baixo |

**Top 3 quick wins:** #1 (output capture), #2 (loop), #3 (orphan fix) — todos baixo esforço, alto impacto.
