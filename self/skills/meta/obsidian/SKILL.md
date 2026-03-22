---
name: meta/obsidian
description: "Auto-ativar quando: qualquer interacao com /workspace/obsidian/ — vault, tasks, agents, inbox, outbox, projetos, grafo. Skill composta: regras de interacao (board, agentroom, graph, dataview) + templates de output (relatorios, dashboards, cards, artefatos)."
---

# Skill: meta/obsidian

> Tudo sobre o vault em `/workspace/obsidian/`. Fonte unica de verdade.
> **Carregar esta skill e obrigatorio antes de qualquer interacao com /workspace/obsidian/.**

## Sub-skills de interacao

| Sub-skill | Arquivo | Quando usar |
|---|---|---|
| **board** | `board.md` | Qualquer interacao com o vault: mapa, tasks, agents, delegacao, quota |
| **agentroom** | `agentroom.md` | Agents interagindo com `/obsidian/agents/`: scheduling, memory, ciclo |
| **graph** | `graph.md` | Manter o grafo Ctrl+G: frontmatter, related, hubs, wiseman |
| **dataview** | `dataview.md` | Queries Dataview/DataviewJS no DASHBOARD.md e notas |

Carregar as que forem relevantes para a task.

---

## Templates de output

Para gravar artefatos persistentes em `/workspace/obsidian/`.

### 1. Relatorio de Inspecao

Template completo: `estrategia/orquestrador/pr-inspector/templates/report.md`

```
obsidian/artefacts/inspect-pr-<N>/
├── README.md     ← indice + frontmatter
└── report.md     ← relatorio completo
```

Frontmatter:
```yaml
---
pr: 1234
repo: monolito
title: "titulo"
author: "fulano"
date: 2026-03-22
inspector: Claude
blockers: 2
warnings: 4
verdict: "SOLICITAR MUDANCAS"
---
```

Secoes: Resumo → Findings por Categoria → Hallucination Check → Pattern Compliance → Veredito

### 2. Dashboard Dataview

```dataview
TABLE status, assignee, due
FROM "tasks/TODO" OR "tasks/DOING"
SORT due ASC
```

```dataview
TABLE last_run, status, findings
FROM "agents"
WHERE last_run
SORT last_run DESC
```

### 3. Card de Agente

Path: `obsidian/agents/<nome>/memory.md`

```yaml
---
agent: <nome>
last_run: 2026-03-22T14:30:00Z
status: idle
next_schedule: 2026-03-22T15:00:00Z
---
```

### 4. Artefato de Projeto

Path: `obsidian/projects/<nome>/`

```yaml
---
project: <nome>
status: active
repos: [monolito, bo-container]
---
```

### 5. Feed / Inbox

Append-only em `obsidian/inbox/feed.md`:
```
[HH:MM] [nome-agente] mensagem curta
```

---

## Convencoes

- Frontmatter YAML sempre no topo
- Datas em ISO 8601 UTC
- Links internos: `[[nome-do-arquivo]]`
- Tags: `#tag` no body, NAO no frontmatter
- Ler `board.md` antes de modificar o vault
