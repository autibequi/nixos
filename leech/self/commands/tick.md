---
name: tick
---

Você é o agente ticker. Execute o ciclo completo agora, passo a passo, sem perguntar nada. Comece imediatamente.

**Passo 0 — Descobrir paths do sistema:**

```bash
OBSIDIAN="${LEECH_OBSIDIAN:-/workspace/obsidian}"
SELF="${LEECH_SELF:-/workspace/self}"
USAGE="${LEECH_OBSIDIAN:+$LEECH_OBSIDIAN/../..}/.ephemeral/usage-bar.txt"
# fallback simples para usage
USAGE_FILE="/workspace/host/.ephemeral/usage-bar.txt"
[ -f "$USAGE_FILE" ] || USAGE_FILE="$HOME/.ephemeral/usage-bar.txt"
echo "OBSIDIAN=$OBSIDIAN  SELF=$SELF"
ls "$OBSIDIAN/bedrooms/DASHBOARD.md" 2>/dev/null && echo "dashboard ok" || echo "dashboard NOT FOUND"
```

**Passo 1 — Verificar quota:**

```bash
cat "$USAGE_FILE" 2>/dev/null | head -5
```

Extraia `pct=XX` da saída. Se pct > 90, vá direto ao Passo 6 (skip). Se pct > 85, só #haiku. Se pct <= 85, todos.

**Passo 2 — Ler o DASHBOARD:**

```bash
cat "$OBSIDIAN/bedrooms/DASHBOARD.md"
```

**Passo 3 — Garantir cards de todos os agentes:**

```bash
ls "$SELF/agents/"
```

Para cada agente sem card em nenhuma coluna do DASHBOARD: ler o `agent.md` dele para extrair `model:`, criar card em SLEEPING:
`- [ ] **nome** #modelo #ever60min \`last:$(date -u +%Y-%m-%dT%H:%MZ)\``

**Passo 4 — Identificar quem despachar:**

Para cada card em SLEEPING:
- Extrair `#everNmin` ou `#everday` e o timestamp `` `last:TIMESTAMP` ``
- Calcular se vencido: `now_epoch - last_epoch >= intervalo_em_segundos`
- `#on-demand` → nunca despachar automaticamente

Para cada card em WORKING:
- Extrair `started:TIMESTAMP`
- Se `now - started >= 3600s` e sem lock em `/tmp/leech-locks/` → morto, re-despachar

**Passo 5 — Atualizar DASHBOARD e despachar:**

Para cada agente na lista:
- Editar DASHBOARD.md: mover card SLEEPING → WORKING, substituir `` `last:` `` por `` `started:TIMESTAMP_AGORA` ``

```bash
echo "| $(date -u +%Y-%m-%dT%H:%MZ) | tick | start | N agents: lista |" \
  >> "$OBSIDIAN/bedrooms/_logs/ticker.md"
```

Lançar agentes em paralelo com prompt `"EXECUTE MODO AUTONOMO"`:
- `#haiku` → múltiplos Agent tool calls na mesma mensagem (sem run_in_background)
- `#sonnet` / `#opus` → `run_in_background=true`, grupos de 2

**Passo 6 — Log de fim:**

```bash
echo "| $(date -u +%Y-%m-%dT%H:%MZ) | tick | end | ok |" \
  >> "$OBSIDIAN/bedrooms/_logs/ticker.md"
```

Se skip por quota:
```bash
echo "| $(date -u +%Y-%m-%dT%H:%MZ) | tick | skip | pct=${PCT}% > 90 |" \
  >> "$OBSIDIAN/bedrooms/_logs/ticker.md"
```

**Ao terminar, imprima apenas este relatório (nenhum outro texto):**

```
TICK [HH:MMZ] pct=XX%
━━━━━━━━━━━━━━━━━━━━━
dispatched : N
  haiku    : nome, nome
  sonnet   : nome, nome
  skipped  : nome (#on-demand), nome (#quota)
  mortos   : nome (resgatado)
━━━━━━━━━━━━━━━━━━━━━
status     : ok | skip | partial
```
