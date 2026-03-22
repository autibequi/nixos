# Graph — Grafo do Obsidian (Ctrl+G)

## Como funciona

Conexoes entre notas via:
1. `[[wikilinks]]` no corpo
2. `related:` no frontmatter (array)
3. Tags — agrupam por cor, nao criam edges

## Nota como hub

```yaml
---
tags: [sistema, meta]
related:
  - "[[DASHBOARD]]"
  - "[[vault/insights]]"
  - "[[vault/WISEMAN]]"
---
```

## Grafo no startup (workspace.json)

```json
{"main":{"type":"split","children":[{"type":"tabs","children":[{"type":"leaf","state":{"type":"graph","state":{}}}]}]}}
```

Obsidian sobrescreve ao fechar — so editar com Obsidian fechado.
Path: `/workspace/obsidian/.obsidian/workspace.json`

## Wiseman mantem o grafo

A cada ciclo:
1. Varrer notas sem `related:` (isoladas)
2. Conectar aos hubs
3. Verificar links quebrados
4. Atualizar `vault/WISEMAN.md`

## Hubs principais

- `vault/WISEMAN.md` — grafo do sistema
- `vault/insights.md` — insights cross-agent
- `DASHBOARD.md` — ponto de entrada

## Boas praticas

- So backlinks semanticamente reais
- Preferir `related:` no frontmatter
- Nota isolada = adicionar 1 link ao hub mais proximo
