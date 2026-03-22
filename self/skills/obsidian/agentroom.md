# Agentroom — Protocolo dos Agents

## Regra Zero — Self-Scheduling

**Nao reagendar = morrer.** Ao final de CADA ciclo:

```bash
NEXT=$(date -d "+N minutes" +%Y%m%d_%H_%M)
mv /workspace/obsidian/agents/_running/*_SEUNOME.md \
   /workspace/obsidian/agents/_schedule/${NEXT}_SEUNOME.md 2>/dev/null
```

- SEMPRE reagendar, mesmo se falhar
- Quota >= 70%: intervalo 2x
- On-demand: +24h heartbeat

## Inicio do Ciclo

```bash
# Skill obsidian ja no contexto (boot injeta)
cat /workspace/obsidian/agents/SEUNOME/memory.md
ls /workspace/obsidian/outbox/para-SEUNOME-*.md 2>/dev/null
```

## Breakroom

```
agents/<nome>/
├── memory.md       — persistente (unico arquivo, atualizar ANTES de reagendar)
├── DIARIO.md       — append-only
├── diarios/        — logs por ciclo
├── outputs/        — artefatos
├── cartas/         — copias CTO
└── done/           — cards concluidos
```

## memory.md

```yaml
---
name: <nome>-memory
type: agent-memory
updated: YYYY-MM-DDTHH:MMZ
---
```

Append ciclo novo no topo. Manter 5-10 ciclos.

## Fim do Ciclo

```
1. [ ] Atualizar memory.md
2. [ ] Append inbox/feed.md se relevante
3. [ ] REAGENDAR (Regra Zero)
```

## Regras

- Nunca commitar sem CTO pedir
- Nunca mover cards DOING/DONE
- Datas absolutas, nunca relativas
