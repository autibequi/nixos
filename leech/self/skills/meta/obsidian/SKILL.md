---
name: meta/obsidian
description: "Interacao com /workspace/obsidian/ — templates, mermaid, graph, dataview. Regras do vault vivem em self/skills/meta/rules/ (nao aqui)."
---

# Skill: meta/obsidian

> Tudo sobre o vault em `/workspace/obsidian/`.
> **Regras de interacao:** `self/RULES.md` (entrypoint) → `self/skills/meta/rules/` (detalhe)

## Sub-skills

| Sub-skill | Arquivo | Quando usar |
|---|---|---|
| **rules** | `self/skills/meta/rules/` | Todas as regras do sistema — ver `/meta:rules` |
| **graph** | `graph.md` | Manter o grafo Ctrl+G: frontmatter, related, hubs, wiseman |
| **dataview** | `dataview.md` | Queries Dataview/DataviewJS no dashboard e notas |

## Templates de output

### Relatorio de Inspecao

Template: `estrategia/orquestrador/pr-inspector/templates/report.md`

```
obsidian/artefacts/inspect-pr-<N>/
├── README.md     ← indice + frontmatter
└── report.md     ← relatorio completo
```

### Card de Agente (memory.md)

```yaml
---
name: <nome>-memory
type: agent-memory
updated: YYYY-MM-DDTHH:MMZ
---
```

### Feed

Append-only em `obsidian/inbox/feed.md`:
```
[HH:MM] [nome-agente] mensagem curta
```

## Mermaid Charts

Obsidian renderiza Mermaid nativamente. Tipos uteis:

| Tipo | Quando usar |
|---|---|
| `xychart-beta` bar | Rankings, scores, totais |
| `xychart-beta` line | Overlay de perfis, comparativos |
| `quadrantChart` | Posicionamento 2D, arquetipos |
| `pie` | Distribuicao proporcional |

Boas praticas:
- Compactar: 1 grafico com overlay > N graficos individuais
- Callout interpretativo junto a cada grafico
- `config: { theme: dark }` para temas escuros
- Linha de referencia (mediana/baseline) em bar charts

## Convencoes Obsidian

- Frontmatter YAML sempre no topo
- Datas em ISO 8601 UTC
- Links internos: `[[nome-do-arquivo]]`
- Tags: `#tag` no body, NAO no frontmatter
- `related:` no frontmatter para edges no graph
- Callouts: `[!example]+` leitura, `[!tip]+` insight, `[!warning]+` gaps
