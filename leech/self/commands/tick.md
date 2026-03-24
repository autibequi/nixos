# /tick — Despachante Central

**EXECUÇÃO AUTÔNOMA. Não perguntar nada. Não explicar o que vai fazer. Executar agora e reportar ao final.**

---

## EXECUTE AGORA

### 1. Quota

```bash
cat /workspace/host/.ephemeral/usage-bar.txt 2>/dev/null | head -5
```

Extrair `pct=` da linha `---API_USAGE---`. Guardar como PCT.

- PCT > 90 → SKIP: ir direto para o Log e encerrar
- PCT > 85 → despachar só #haiku
- PCT <= 85 → despachar todos

### 2. Ler DASHBOARD

```bash
cat /workspace/obsidian/bedrooms/DASHBOARD.md
```

### 3. Garantir todos os agentes têm card

```bash
ls /workspace/self/agents/
```

Para cada agente sem card em nenhuma coluna do DASHBOARD: criar card em SLEEPING:
```
- [ ] **nome** #modelo #ever60min `last:TIMESTAMP_AGORA`
```
(extrair `model:` do frontmatter de `agents/nome/agent.md` para determinar #modelo)

### 4. Identificar quem despachar

**SLEEPING com schedule vencido:**
- Extrair `#everNmin` ou `#everday` do card
- Extrair timestamp `last:TIMESTAMP`
- Calcular: `now_epoch - last_epoch >= intervalo_segundos`
- `#on-demand` → NUNCA despachar

**WORKING mortos (>1h):**
```bash
ls /tmp/leech-locks/ 2>/dev/null
```
- Card em WORKING com `started:TIMESTAMP` onde `now - started >= 3600s` e sem lock ativo → morto, re-despachar

### 5. Atualizar DASHBOARD

Para cada agente a despachar: editar DASHBOARD.md movendo card de SLEEPING→WORKING.
Substituir `` `last:TIMESTAMP` `` por `` `started:TIMESTAMP_AGORA` ``

Fazer tudo em uma edição consolidada.

### 6. Log de início

```bash
echo "| $(date -u +%Y-%m-%dT%H:%MZ) | tick | start | N agents: lista |" \
  >> /workspace/obsidian/bedrooms/_logs/ticker.md
```

### 7. Despachar

Prompt exato para cada agente: **`EXECUTE MODO AUTONOMO`**

- `#haiku` → lançar em paralelo (múltiplos Agent tool calls na mesma mensagem)
- `#sonnet` / `#opus` → `run_in_background=true`, grupos de 2

Se PCT > 90: pular esta etapa.
Se PCT > 85: lançar apenas #haiku.

### 8. Log de fim

```bash
echo "| $(date -u +%Y-%m-%dT%H:%MZ) | tick | end | ok |" \
  >> /workspace/obsidian/bedrooms/_logs/ticker.md
```

Se skip:
```bash
echo "| $(date -u +%Y-%m-%dT%H:%MZ) | tick | skip | pct=${PCT}% > 90 |" \
  >> /workspace/obsidian/bedrooms/_logs/ticker.md
```

---

## RELATÓRIO FINAL

Ao terminar, imprimir apenas:

```
TICK [HH:MMZ] pct=XX%
━━━━━━━━━━━━━━━━━━━━━
dispatched : N agents
  haiku    : nome, nome, nome
  sonnet   : nome, nome
  skipped  : nome (#on-demand), nome (#quota)
  mortos   : nome (resgatado)
━━━━━━━━━━━━━━━━━━━━━
status     : ok | skip | partial
```

Nenhum outro texto. Nenhuma pergunta. Nenhuma explicação.
