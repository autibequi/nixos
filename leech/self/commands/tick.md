# /tick — Despachante Central

> Sem conversa. Sem output desnecessário. Ler DASHBOARD, decidir, despachar, logar.

---

## Fase 1 — Verificar Quota

```bash
cat /workspace/host/.ephemeral/usage-bar.txt 2>/dev/null | head -3
```

Extrair `pct=` da linha `---API_USAGE---`. Regras:
- `pct > 90`: SKIP total — logar e encerrar
- `pct > 85 e <= 90`: despachar só #haiku
- `pct <= 85`: despachar todos (#haiku + #sonnet + #opus)

---

## Fase 2 — Ler DASHBOARD

```bash
cat /workspace/obsidian/bedrooms/DASHBOARD.md
```

Parsear o kanban:
- **SLEEPING**: cards com `- [ ] **nome**`
- **WORKING**: cards em execução
- **DONE**: cards idle
- **WAITING**: cards aguardando usuário (não tocar — são decisão humana)

---

## Fase 3 — Garantir Todos os Agentes Têm Card

Listar todos os agentes conhecidos:
```bash
ls /workspace/self/agents/
```

Para cada agente sem card no DASHBOARD: adicionar na coluna SLEEPING com as tags corretas do seu `agent.md` (extrair `model:` do frontmatter para #modelo, `clock:` para #schedule).

Formato de card novo:
```
- [ ] **nome** #modelo #schedule `last:TIMESTAMP_AGORA`
```

Timestamp: `$(date -u +%Y-%m-%dT%H:%MZ)`

---

## Fase 4 — Identificar Agentes a Despachar

### A. SLEEPING com schedule vencido

Para cada card em SLEEPING com `#everXmin` ou `#everday`:
- Extrair o timestamp `` `last:TIMESTAMP` ``
- Calcular se vencido: `now - last >= schedule_interval`
- Se vencido E modelo permitido pela quota → **adicionar à lista de despacho**
- `#on-demand`: NUNCA despachar automaticamente

### B. WORKING mortos (> 1h sem lock)

Para cada card em WORKING com `` `started:TIMESTAMP` ``:
```bash
# Verificar locks ativos
ls /tmp/leech-locks/ 2>/dev/null
```
- Se `now - started >= 3600s` E sem lock ativo em `/tmp/leech-locks/` → tratar como morto
- Mover card de volta para SLEEPING e adicionar à lista de despacho

---

## Fase 5 — Atualizar DASHBOARD

Para cada agente na lista de despacho:
- Mover card de SLEEPING → WORKING no DASHBOARD.md
- Substituir `` `last:TIMESTAMP` `` por `` `started:TIMESTAMP_AGORA` ``

Editar DASHBOARD.md com as mudanças acumuladas (uma edição consolidada).

---

## Fase 6 — Logar Início

```bash
NOW=$(date -u +%Y-%m-%dT%H:%MZ)
LISTA="agente1,agente2,agente3"
echo "| $NOW | tick | start | ${N} agents: $LISTA |" \
  >> /workspace/obsidian/bedrooms/_logs/ticker.md
```

---

## Fase 7 — Despachar em Paralelo

Prompt para cada agente: `"EXECUTE MODO AUTONOMO"`

**Agentes #haiku** — lançar em paralelo (uma mensagem, múltiplos tool calls Agent):
- Usar `subagent_type` do agente (ou inferir pelo model)
- Não usar `run_in_background` para haiku (são rápidos)

**Agentes #sonnet e #opus** — `run_in_background=true`, grupos de 2 para não sobrecarregar

Se pct > 85: lançar apenas agentes #haiku.
Se pct > 90: SKIP, não lançar nenhum.

---

## Fase 8 — Logar Fim

```bash
NOW=$(date -u +%Y-%m-%dT%H:%MZ)
echo "| $NOW | tick | end | ok |" \
  >> /workspace/obsidian/bedrooms/_logs/ticker.md
```

Se SKIP por quota:
```bash
echo "| $NOW | tick | skip | pct=${PCT}% > 90 |" \
  >> /workspace/obsidian/bedrooms/_logs/ticker.md
```

---

## Regras Absolutas

- NUNCA tocar cards em WAITING (são para o usuário)
- NUNCA commitar
- NUNCA despachar agentes #on-demand automaticamente
- Se agente falhar no despacho: continuar com os demais, logar o erro
- Ciclo vazio (nenhum vencido, nenhum morto) = encerrar silenciosamente após logar
- Sempre encerrar com log de fim
