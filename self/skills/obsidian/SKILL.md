---
name: obsidian
description: "Auto-ativar quando: qualquer interacao com /workspace/obsidian/ — vault, tasks, agents, inbox, outbox, projetos, grafo. Skill composta com 4 sub-skills."
---

# Skill: Obsidian

> Tudo sobre o vault em `/workspace/obsidian/`. Fonte unica de verdade.
> **Carregar esta skill e obrigatorio antes de qualquer interacao com /workspace/obsidian/.**

## Sub-skills

| Sub-skill | Arquivo | Quando usar |
|-----------|---------|-------------|
| **board** | `board.md` | Qualquer interacao com o vault: mapa, tasks, agents, delegacao, quota |
| **agentroom** | `agentroom.md` | Agents interagindo com `/obsidian/agents/`: scheduling, memory, ciclo |
| **graph** | `graph.md` | Manter o grafo Ctrl+G: frontmatter, related, hubs, wiseman |
| **dataview** | `dataview.md` | Queries Dataview/DataviewJS no DASHBOARD.md e notas |

Cada sub-skill e um arquivo .md nesta pasta. Carregar as que forem relevantes para a task.
