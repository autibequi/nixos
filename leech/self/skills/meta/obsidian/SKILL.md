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
| **agentroom** | `agentroom.md` | Agents interagindo com `/obsidian/bedrooms/`: scheduling, memory, ciclo |
| **law** | `law.md` | A Lei do Leech: 9 leis obrigatorias + penalidades. Wiseman fiscaliza. |
| **graph** | `graph.md` | Manter o grafo Ctrl+G: frontmatter, related, hubs, wiseman |
| **dataview** | `dataview.md` | Queries Dataview/DataviewJS no bedrooms/dashboard.md e notas |

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

Path: `obsidian/bedrooms/<nome>/memory.md`

```yaml
---
agent: <nome>
last_run: 2026-03-22T14:30:00Z
status: idle
next_schedule: 2026-03-22T15:00:00Z
---
```

### 4. Artefato de Projeto

Path: `obsidian/workshop/<nome>/`

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

## Mermaid Charts

O Obsidian renderiza Mermaid nativamente. Usar para visualizacoes que ASCII nao consegue representar bem.

### Tipos uteis

| Tipo | Quando usar | Exemplo |
|---|---|---|
| `xychart-beta` bar | Rankings, scores, totais | Score total por dev |
| `xychart-beta` line | Overlay de perfis, comparativos multi-dimensao | 7 devs x 8 dimensoes no mesmo grafico |
| `xychart-beta` bar+line | Valores + referencia (mediana, baseline) | Score com linha de mediana |
| `quadrantChart` | Posicionamento 2D, arquetipos, trade-offs | Rigor vs Pragmatismo |
| `pie` | Distribuicao proporcional | Cobertura de testes por camada |

### Boas praticas

- **Compactar:** prefira 1 grafico com overlay de multiplas series do que N graficos individuais. Um `xychart-beta` com 7 `line` substitui 7 radars + 8 comparativos por dimensao.
- **Contexto narrativo:** cada grafico deve ter um callout (`> [!example]+`, `> [!tip]+`) explicando o insight principal — o grafico mostra, o callout interpreta.
- **Theme dark:** usar `config: { theme: dark }` para consistencia com temas escuros.
- **Linha de referencia:** em bar charts comparativos, adicionar `line "Mediana"` ou `line "Baseline L4"` como referencia visual.
- **Quadrant para arquetipos:** mapear devs/conceitos em 2 eixos complementares (ex: simplicidade↔extensibilidade, pragmatismo↔rigor).
- **Duelos:** agrupar por tier (top tier bar vs mid tier line) para manter legibilidade com muitas series.

### Estrutura de um ranking Mermaid

```markdown
## Score Total
xychart-beta bar + line mediana

## DNA / Fingerprint
xychart-beta com N lines overlaid (o grafico principal)
callout com leitura dos picos e vales

## Duelos por tier
2-3 xychart-beta agrupando por nivel

## Arquetipos
quadrantChart posicionando cada item

## Saude / Media
xychart-beta bar media + line baseline
callout com gaps criticos

## Tabelas
Lideranca por dimensao, pares complementares, evolucao
```

## Convencoes

- Frontmatter YAML sempre no topo
- Datas em ISO 8601 UTC
- Links internos: `[[nome-do-arquivo]]`
- Alias em wikilinks: `[[arquivo|nome exibido]]`
- Tags: `#tag` no body, NAO no frontmatter
- `related:` no frontmatter para edges no graph (array de wikilinks)
- Callouts para interpretar dados: `[!example]+` leitura, `[!tip]+` insight, `[!warning]+` gaps, `[!success]+` conclusao
- Ler `board.md` antes de modificar o vault
