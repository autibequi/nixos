# Proposta V5: Melhorias de Automação do Claudinho

> Consolidada em 2026-03-13T06:28Z. Baseada em dados reais de execução e 4 iterações anteriores.

## Diagnóstico Atual

- **`clau-new`** — ✅ implementado
- **Workers paralelos** — ✅ implementado, mas sem limite de concorrência
- **Problema crítico:** 10 de 14 runs recentes falharam com `fail:124` (timeout). Causa: spawnar 1 worker por task sem limite = contenção de recursos + rate limiting da API

---

## Prioridade Crítica

### 1. Limitar concorrência de workers
**O que:** `MAX_WORKERS=3` no `make clau` e no `claude-autonomous.nix`. Spawnar no máximo N containers.
**Por que:** 9+ workers simultâneos = todos falham por timeout. É o gargalo #1 do sistema hoje.
**Esforço:** Baixo.
```makefile
MAX_WORKERS ?= 3
# No loop, adicionar:
[ "$$count" -ge "$(MAX_WORKERS)" ] && echo "[clau] Max workers atingido" && break;
```

### 2. Capturar output das execuções
**O que:** Redirecionar stdout/stderr do Claude para `.ephemeral/notes/<task>/last-run.log`.
**Por que:** Tasks falham sem deixar rastro. `logs-host-readonly` falhou em 1s sem explicação.
**Esforço:** Baixo — `| tee "$CONTEXT_DIR/last-run.log"` no runner.

### 3. Reconciliar timeouts systemd vs makefile
**O que:** `claude-autonomous.nix` passa 300s, `makefile` passa 600s. Alinhar.
**Por que:** Inconsistência causa comportamento imprevisível. Worker do timer morre antes.
**Esforço:** Baixo — valor sugerido: 480s (margem pro cleanup antes do `TimeoutStartSec=10min`).

---

## Prioridade Alta

### 4. Timeout configurável por task
**O que:** Campo no CLAUDE.md (ex: `<!-- timeout: 300 -->`) com fallback pro default.
**Por que:** Doctor não precisa de 10min. Review de código precisa de mais. One-size-fits-all causa desperdício ou timeout.
**Esforço:** Baixo — `grep -oP` no CLAUDE.md.

### 5. Fix: orphan reap não respeita source
**O que:** Orphans sem lock vão sempre pra `pending/` (linha 34 do runner), mesmo recurring.
**Por que:** Recurring que crasha perde imortalidade e vira one-shot.
**Esforço:** Baixo — salvar `source` num `.meta` ao criar a task, ou inferir pelo diretório de origem.

### 6. Health check pré-execução
**O que:** Verificar API key, espaço em disco, e CLI acessível antes de spawnar workers.
**Por que:** Se API key expirou ou disco lotou, TODAS as tasks falham. Detectar antes evita desperdício.
**Esforço:** Baixo — ~10 linhas no início do runner.

### 7. `clau-status` com contexto rico
**O que:** Mostrar último status, duração e objetivo de cada task (não só `ls -1`).
**Por que:** Com 10+ tasks, `ls` é inútil. Precisa de overview rápido.
**Esforço:** Baixo — ler `historico.log` + `head -3 CLAUDE.md`.

### 8. Fix: `\n` literal no echo do makefile
**O que:** `@echo "\n=== ..."` não funciona sem `-e`. Trocar por `@echo ""` + `@echo "=== ..."`.
**Esforço:** Baixo — 5 substituições no makefile.

---

## Prioridade Média

### 9. Notificação desktop pós-execução
**O que:** `notify-send` quando task termina.
**Por que:** Container já tem Wayland socket. Falta `libnotify` no Dockerfile.
**Esforço:** Baixo.

### 10. Dockerfile: layer caching + pin versão
**O que:** (a) Separar `nix profile install` em layers estáveis vs voláteis. (b) Pinar versão do `@anthropic-ai/claude-code`.
**Por que:** Qualquer mudança no bloco nix invalida todo cache. `npm install -g` sem versão = builds instáveis.
**Esforço:** Médio.

### 11. Usage JSONL: schema inconsistente
**O que:** Primeira entry do mês não tem `status`/`type`. Provavelmente bug corrigido mid-session.
**Por que:** Quebra `jq` queries e `make usage`.
**Esforço:** Baixo — fallback no jq + validação no runner.

### 12. Target `make clau-logs`
**O que:** `make clau-logs task=<name>` mostra último output + histórico da task.
**Por que:** Complementa #2 — sem forma rápida de ler logs, capturar output é inútil.
**Esforço:** Baixo.

### 13. Stow drift detection
**O que:** `make stow-diff` comparando `stow/` com `$HOME`.
**Por que:** Apps reescrevem configs. Stow fica out-of-sync silenciosamente.
**Esforço:** Médio.

### 14. Retry automático para one-shot
**O que:** Campo `max_retries` no CLAUDE.md. Runner faz requeue em vez de `failed/`.
**Por que:** Falhas transientes matam tasks viáveis.
**Esforço:** Médio.

### 15. Limpeza automática de done/failed
**O que:** Target `make clau-gc` que remove pastas em `done/`/`failed/` com mais de 7 dias.
**Por que:** Acumulam-se silenciosamente.
**Esforço:** Baixo.

---

## Prioridade Baixa

### 16. Task `.meta` unificado
**O que:** Arquivo `.meta` com `source`, `priority`, `max_retries`, `created_at`.
**Por que:** Resolve #5, #14, e prioridade de uma vez. Base para features futuras.
**Esforço:** Médio.

### 17. docker-compose healthcheck
**O que:** Healthcheck no serviço sandbox.
**Esforço:** Baixo-médio.

### 18. Documentar requisito Podman
**O que:** `userns_mode: keep-id` é Podman-only. Documentar ou adicionar fallback.
**Esforço:** Baixo.

### 19. Watchdog: recurring sem execução
**O que:** Alertar se recurring nunca rodou em 24h+.
**Por que:** Recurring ficam atrás de pending na fila. Sem #1, nunca executam.
**Esforço:** Baixo.

### 20. Dependências entre tasks
**O que:** Campo `depends_on` para pipelines.
**Esforço:** Alto.

---

## Resumo Executivo

| # | Melhoria | Esforço | Impacto |
|---|----------|---------|---------|
| 1 | **Limitar concorrência workers** | Baixo | **Crítico** |
| 2 | Capturar output | Baixo | Alto |
| 3 | Reconciliar timeouts | Baixo | Alto |
| 4 | Timeout por task | Baixo | Alto |
| 5 | Fix orphan reap | Baixo | Alto |
| 6 | Health check pré-exec | Baixo | Médio |
| 7 | clau-status rico | Baixo | Médio |
| 8 | Fix echo \n | Baixo | Baixo |
| 9 | Notificação desktop | Baixo | Médio |
| 10 | Dockerfile layers+pin | Médio | Médio |
| 11 | Fix JSONL schema | Baixo | Baixo |
| 12 | `clau-logs` target | Baixo | Médio |
| 13 | Stow drift | Médio | Médio |
| 14 | Retry automático | Médio | Médio |
| 15 | Limpeza done/failed | Baixo | Baixo |
| 16-20 | Baixa prioridade | Médio-Alto | Baixo |

**Ação imediata recomendada:** #1 + #2 + #3 (limitar concorrência, capturar output, alinhar timeouts) — resolvem a epidemia de timeouts que é o problema dominante hoje.
