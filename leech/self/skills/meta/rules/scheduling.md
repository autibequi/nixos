---
maintainer: wiseman
updated: 2026-03-23T16:00Z
---

# Scheduling

## Agentes Periodicos

Fila de execucao em `tasks/AGENTS/`:
- Um card por agente com clock definido — sempre presente
- On-demand (mechanic, tasker): so aparecem quando convocados
- Formato: `YYYYMMDD_HH_MM_<nome>.md`

Fluxo:
```
tasks/AGENTS/ → tasks/AGENTS/DOING/ → reagenda (volta) ou bedrooms/<nome>/done/
```

## Tasks One-Off

Fluxo:
```
tasks/TODO/ → tasks/DOING/ → tasks/DONE/ → _archive/ (30d)
```

- Hermes cria em TODO a partir de outbox
- Runner move TODO → DOING → DONE
- Agentes nunca movem DOING/DONE manualmente

**Constraints de agendamento (hermes):**
- Nunca criar card para agente que nao tem `self/agents/<nome>/agent.md`
- Nunca agendar 2 agentes sonnet no mesmo slot de minuto
- Maximo 3 cards agendados por agente nas proximas 2h
- Nunca agendar sonnet quando quota >= 70% — apenas haiku

---

Card minimo:
```yaml
---
model: haiku|sonnet|opus
timeout: 900
agent: <nome>
---
Instrucao completa. #steps20
```
