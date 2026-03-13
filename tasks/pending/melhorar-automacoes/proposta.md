# Proposta V3: Melhorias de Automação do Claudinho

> V3 — Refinada com dados reais de execução (2026-03-13). Tasks `paralelizar-trabalho` e `formas-de-adicionar-tasks` já investigam itens relacionados.

## Status de Implementação

| # | Melhoria | Status |
|---|----------|--------|
| 3 (V1) | `clau-new` template | ✅ Implementado |
| 1-15 (V2) | Demais itens | Pendentes |

---

## Prioridade Alta (maior valor / menor esforço)

### 1. Runner: capturar output das execuções
**O que:** Salvar stdout/stderr do Claude em `.ephemeral/notes/<task>/last-output.log`.
**Por que:** `logs-host-readonly` falhou com `fail:1` em 1s e não há como debugar — só temos o status no historico.log. A entry de usage de `melhorar-automacoes` da primeira run sequer tem campo `status` (JSON incompleto).
**Esforço:** Baixo — `| tee "$OUTPUT_LOG"` no comando do runner.
**Evidência real:** `2026-03-13T05:24:04Z | fail:1 | 1s` — impossível diagnosticar sem log.

### 2. Runner: loop multi-tarefa por execução
**O que:** Processar todas as pending + 1 recurring por invocação do `make clau`.
**Por que:** Com 3 pending na fila agora (`paralelizar-trabalho`, `review-cached-ldi-toc`, `review-delta-lake`), leva 3+ horas com o timer horário. Um loop sequencial limpa em ~30-40min.
**Esforço:** Baixo — `while true` em volta do bloco pick+execute, break quando não houver mais.
**Nota:** Task `paralelizar-trabalho` investiga containers paralelos; este é o quick-win sequencial imediato.

### 3. Runner: orphan reap não respeita source
**O que:** Linha 48 do runner: orphans vão sempre pra `pending/`, mesmo recurring.
**Por que:** Recurring que crashou sem lock vira one-shot e perde imortalidade.
**Esforço:** Baixo — criar `.meta` com `source=recurring|pending` na pasta da task, ou inferir pelo conteúdo do CLAUDE.md (presença de "Auto-evolução").

### 4. Makefile: `clau-status` bugado com `\n`
**O que:** `@echo "\n=== ..."` — `\n` literal no bash sem `-e`.
**Por que:** Output confuso, dificulta leitura rápida.
**Esforço:** Baixo — substituir por `@echo ""` separado.

### 5. clau-status: mostrar contexto rico
**O que:** Além do nome da task, mostrar: último status, duração, e primeira linha do objetivo.
**Por que:** `ls -1` é inútil. Com 4 recurring + 3 pending, precisa de overview útil.
**Esforço:** Baixo — ler `historico.log` e `CLAUDE.md`.
**Exemplo de output:**
```
=== Pending (one-shot) ===
  paralelizar-trabalho  (never run)  "Pesquisar formas de paralelizar..."
  review-cached-ldi-toc (never run)  "Validar implementação cached-ldi-toc"
=== Recurring (imortais) ===
  doctor               (never run)  "Verificar saúde do container"
  usage-tracker        (never run)  "Tracking de uso"
```

### 6. Runner: notificação pós-execução
**O que:** `notify-send` quando task termina.
**Por que:** Tasks rodam silenciosas. Wayland socket já está montado no container.
**Esforço:** Baixo — Precisa instalar `libnotify` no Dockerfile (1 pacote nix extra).

---

## Prioridade Média

### 7. Usage JSONL: schema inconsistente
**O que:** Primeira entry do mês não tem `status` nem `type`:
```json
{"date":"2026-03-13T05:06:58Z","task":"melhorar-automacoes","duration":142}
```
Demais entries têm schema completo.
**Por que:** Quebra `jq` queries e `make usage`. Provavelmente bug corrigido mid-session no runner.
**Esforço:** Baixo — validar no runner que todos os campos existem; adicionar fallback `|| "unknown"` no jq do `make usage`.

### 8. Dockerfile: layer caching + versionamento
**O que:** (a) Separar `nix profile install` em layers estáveis vs voláteis. (b) Pinar `@anthropic-ai/claude-code` versão.
**Por que:** Qualquer mudança no bloco nix invalida todo o cache. `npm install -g` sem versão quebra builds quando há breaking change.
**Esforço:** Médio.

### 9. docker-compose: healthcheck
**O que:** Adicionar healthcheck ao serviço sandbox.
**Por que:** `docker compose up -d` retorna OK mesmo se container crashar.
**Esforço:** Baixo-médio.

### 10. Stow: detecção de drift
**O que:** Target `make stow-diff` comparando `stow/` com `$HOME`.
**Por que:** Apps reescrevem configs (Zed, VS Code). Stow fica desatualizado silenciosamente.
**Esforço:** Médio.

### 11. Runner: retry automático
**O que:** Campo `max_retries: N` no CLAUDE.md ou `.meta`. Runner faz requeue em vez de `failed/`.
**Por que:** `logs-host-readonly` falhou 1x em 1s (provavelmente transiente) e morreu.
**Esforço:** Médio.

### 12. Makefile: target `clau-logs`
**O que:** `make clau-logs name=<task>` mostra último output + histórico.
**Por que:** Complementa #1. Sem forma rápida de ler logs = logs inúteis.
**Esforço:** Baixo.

---

## Prioridade Baixa

### 13. Task metadata: arquivo `.meta`
**O que:** Cada task ganha um `.meta` com campos estruturados: `source`, `priority`, `max_retries`, `created_at`.
**Por que:** Resolve #3 (orphan reap), #11 (retry), e #13-antigo (prioridade) de uma vez. Runner parseia com `grep/cut`.
**Esforço:** Médio — precisa criar `.meta` no `clau-new` e adaptar runner.

### 14. Task dependências
**O que:** Campo `depends_on` no `.meta` para pipelines.
**Por que:** Permitiria "gera migration → atualiza handler → testa".
**Esforço:** Alto.

### 15. docker-compose: `userns_mode: keep-id` é Podman-only
**O que:** Essa flag não existe no Docker. Se mudar de Podman, quebra.
**Por que:** Portabilidade.
**Esforço:** Baixo — documentar ou usar `user: "1000:1000"` como fallback.

### 16. Runner: watchdog para recurring sem execução
**O que:** Alertar se alguma recurring nunca rodou (como `doctor`, `avaliar-m5`, `parceiro`, `usage-tracker` — todas com 0 runs até agora).
**Por que:** 4 recurring criadas mas nunca executaram porque sempre há pending na fila. O loop multi-tarefa (#2) resolve isso parcialmente.
**Esforço:** Baixo — checar no runner se há recurring com `last_epoch=0` há mais de 24h.

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
| 7 | Fix JSONL schema | Baixo | Médio |
| 8 | Dockerfile layers + pin | Médio | Médio |
| 9 | Healthcheck container | Baixo-Médio | Médio |
| 10 | Stow drift detection | Médio | Médio |
| 11 | Retry automático | Médio | Médio |
| 12 | `clau-logs` target | Baixo | Médio |
| 13 | Task `.meta` unificado | Médio | Médio |
| 14 | Dependências de tasks | Alto | Baixo |
| 15 | Documentar Podman req | Baixo | Baixo |
| 16 | Watchdog recurring sem run | Baixo | Médio |

**Top 3 quick wins:** #1 (output capture), #2 (loop multi-tarefa), #3 (orphan fix).

**Achado novo desta execução:** 4 recurring tasks nunca rodaram porque pending monopoliza a fila — #2 (loop) e #16 (watchdog) resolvem isso.

---

## Achados da Execução V4 (2026-03-13T06:26Z)

### CRÍTICO: Epidemia de timeouts (fail:124)

Desde a última execução (~06:05Z), **todas** as tasks estão falhando com `fail:124` (timeout 600s). Isso inclui recurring (doctor, parceiro, avaliar-m5, usage-tracker) e pending (review-delta-lake, paralelizar-trabalho, pesquisar-controle-tokens, review-cached-ldi-toc). Até esta própria task (melhorar-automacoes) falhou com timeout na run anterior.

**Hipóteses:**
1. **Muitos workers simultâneos** — `make clau` spawna 1 worker por task em paralelo. Com 10+ tasks, são 10+ containers Claude rodando ao mesmo tempo, disputando CPU/memória/rate limits da API Anthropic.
2. **Rate limiting da API** — 10 instâncias Claude simultâneas quase certamente batem no rate limit, causando retries exponenciais que estouram o timeout de 600s.
3. **OOM no host** — cada container Claude consome memória significativa.

**Proposta nova #17: Limitar concorrência de workers**
- **O quê:** No `make clau`, limitar a N workers simultâneos (ex: 2-3). Usar `xargs -P3` ou semáforo com flock.
- **Por que:** Resolve a epidemia de timeouts. Menos workers = menos contenção = cada um termina no tempo.
- **Esforço:** Baixo — trocar o loop `for task... &` por `xargs -P$MAX_WORKERS`.
- **Impacto:** **Crítico** — sem isso, o sistema inteiro trava quando há muitas tasks.

**Proposta nova #18: Timeout proporcional ao tipo de task**
- **O quê:** Recurring tasks com timeout menor (300s), pending com timeout default (600s). Ou configurável via `.meta`.
- **Por que:** Doctor e usage-tracker não precisam de 10min. Tasks que sabem que são rápidas não deveriam bloquear slot por 10min.
- **Esforço:** Baixo.

### Status atualizado: recurring agora executam, mas falham

As 4 recurring (doctor, parceiro, avaliar-m5, usage-tracker) finalmente rodaram (não estão mais com 0 runs), mas todas com fail:124. O loop multi-tarefa (#2) está funcionando, o problema agora é contenção (#17).
