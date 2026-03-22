---
name: art/obsidian
description: Templates de visualizacao para o vault Obsidian. Relatorios, dashboards Dataview, cards de agentes, artefatos persistentes.
---

# Obsidian — Representacoes no Vault

Para artefatos que precisam persistir alem da sessao. Gravados em `/workspace/obsidian/`.

---

## 1. Relatorio de Inspecao

Template completo: `orquestrador/pr-inspector/templates/report.md`

Estrutura:
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
title: "Cached TOC para LDI"
author: "fulano"
date: 2026-03-22
inspector: Claude
blockers: 2
warnings: 4
verdict: "SOLICITAR MUDANCAS"
---
```

Secoes: Resumo → Findings por Categoria → Hallucination Check → Pattern Compliance → Veredito

---

## 2. Dashboard Dataview

Para dashboards que atualizam automaticamente no Obsidian:

```markdown
## Tasks Ativas

```dataview
TABLE status, assignee, due
FROM "tasks/TODO" OR "tasks/DOING"
SORT due ASC
```​

## Agentes — Ultimo Ciclo

```dataview
TABLE last_run, status, findings
FROM "agents"
WHERE last_run
SORT last_run DESC
```​
```

---

## 3. Card de Agente (breakroom)

Path: `obsidian/agents/<nome>/memory.md`

```markdown
---
agent: <nome>
last_run: 2026-03-22T14:30:00Z
status: idle
next_schedule: 2026-03-22T15:00:00Z
---

## Memory

<contexto persistente do agente>

## Done

<historico de ciclos completados>
```

---

## 4. Artefato de Projeto

Path: `obsidian/projects/<nome>/`

```markdown
---
project: <nome>
status: active
repos: [monolito, bo-container]
---

## Overview

<descricao do projeto>

## Ideas

<lista de ideias/exploracoes>

## Insights

<aprendizados>
```

---

## 5. Feed / Inbox

Append-only em `obsidian/inbox/feed.md`:

```
[14:30] [agente] mensagem curta sobre o que fez ou descobriu
[14:45] [outro-agente] outra mensagem
```

Formato: `[HH:MM] [nome-agente] mensagem`

---

## Convencoes

- Frontmatter YAML sempre no topo
- Datas em ISO 8601 UTC
- Links internos: `[[nome-do-arquivo]]`
- Tags: `#tag` no body, NAO no frontmatter (exceto campos estruturados)
- Antes de modificar o vault, ler `skills/obsidian/board.md` (regras do board)
