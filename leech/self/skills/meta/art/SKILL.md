---
name: meta/art
description: Arte visual do Leech — ASCII terminal, animacoes artisticas no Chrome (eye, glados), voz. Para flowcharts e visualizacoes de dados, usar meta/holodeck.
---

# /meta:art — Arte Visual

Skill de arte pura: terminal, animacoes, voz. Nao e para dados nem diagramas.

> **Flowcharts, dashboards, Mermaid com dados?** → `meta/holodeck`

## Design System

**Ler `design-system.md` PRIMEIRO** — palette testada, tokens, emojis proibidos, regras de composicao.

## Sub-skills

| Arquivo | Conteudo | Quando usar |
|---|---|---|
| `design-system.md` | Palette Catppuccin, tokens, box drawing | Sempre — antes de qualquer output |
| `ascii.md` | 19 templates de representacao terminal | Default. Sem dependencia. |
| `chrome.md` | Voz + templates artisticos (eye, glados) + **canvas colaborativo** | Arte no browser. Precisa relay. |
| `meta/obsidian` | Relatorios + Dataview | Artefatos persistentes no vault. |

## Regra de decisao

```
Precisa de visualizacao?
    │
    ├── e dado/flow/diagrama?
    │     └─ meta/holodeck
    │
    ├── Cabe no terminal? (< 80 linhas)
    │     └─ ascii.md
    │
    ├── Arte no Chrome? (eye, glados, animacao, voz)
    │     └─ chrome.md
    │
    ├── Diagrama colaborativo interativo? (user + eu iteramos juntos)
    │     └─ chrome.md → Canvas Colaborativo
    │
    └── Precisa persistir no vault?
          └─ meta/obsidian
```

## Para agentes e skills externos

Se voce e um agente ou skill que precisa desenhar algo:

1. **NAO invente seu proprio formato** — consulte esta skill
2. Leia o sub-file do tipo de saida que precisa
3. Use os templates e convencoes documentados
4. Se criar um novo tipo de visualizacao que ficou bom, adicione aqui

## Catalogo rapido (o que temos)

### ASCII (terminal) — 18 tipos
- 1 Fluxo de handler (mini-guia horizontal + deep-dive vertical)
- 2 Mapa de caixas (black boxes com IN/OUT)
- 3 Logica interna (if/else, errgroup, loop, graceful degradation)
- 4 Diagrama multi-path (read + write + guard)
- 5 Tabelas de status (ok/!!/XX)
- 6 Graficos de barra horizontal
- 7 Arvore de arquivos
- 8 Headers de secao
- 9 Tabela comparativa (antes/depois)
- 10 Sequencia temporal (timeline)
- 11 Diagrama de entidade/struct
- 12 Mapa de dependencias (quem chama quem)
- 13 Diff inline (antes/depois no mesmo bloco)
- 14 Matriz de cobertura (testes vs objetos)
- 15 Fluxo de estado (state machine)
- 16 Calendario/sprint
- 17 Kanban compacto
- 18 Grafico de proporcao (pizza horizontal)
- 19 Stacked bar vertical / termômetro (3 variantes: grossa, zoom, duplo painel) — usar em breakdowns de budget/tokens

### Chrome (relay) — inclui controle completo do browser
- Verificacao de disponibilidade + regra de decisao
- Comandos: nav, show, tabs, speak, present
- Diagrama Mermaid (flowchart com tema Catppuccin) — **fullscreen por default** (sem containers), zoom+drag, auto-fullscreen do browser, diagrama centralizado
- Arvore de diff interativa (collapse, glow, breadcrumb)
- **Code diff side-by-side** — diff2html-cli dark + JetBrains Mono → ver `code/analysis/diff/codediff.md`
- **Canvas colaborativo** — diagramacao interativa user+eu em tempo real (`host/leech/tools/chrome/canvas/index.html`)
  - API: `CANVAS.addNode/addEdge/addText/layout/state/clear`
  - Fluxo: abrir → user manipula → `CANVAS.state()` → eu itero em cima
- HTML livre com CDN (diff2html, Chart.js, Mermaid, D3, DataTables...)
- Voz (espeak-ng via relay)

### Obsidian (vault)
- Relatorio de inspecao (frontmatter + findings)
- Dashboard Dataview (queries inline)
- Cards de agentes (frontmatter estruturado)
