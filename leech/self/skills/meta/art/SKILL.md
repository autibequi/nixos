---
name: meta/art
description: Biblioteca central de representacoes visuais do Leech + controle do Chrome relay. 3 modos de saida (ASCII terminal, Chrome relay, Obsidian). Qualquer skill ou agente que precise desenhar algo ou usar o Chrome referencia esta skill.
---

# /meta:art — Biblioteca Visual do Leech

Skill composta com 3 sub-skills por tipo de saida. **Fonte da verdade** para qualquer representacao visual no sistema e para o controle do Chrome relay (CDP).

## Design System

**Ler `design-system.md` PRIMEIRO** — palette de cores testada, tokens semanticos, emojis proibidos, regras de composicao. Fonte da verdade para qualquer output visual.

## Sub-skills

| Arquivo | Conteudo | Quando usar |
|---|---|---|
| `design-system.md` | Palette, tokens, box drawing, regras, Catppuccin CSS, Mermaid theme | **Sempre** — ler antes de qualquer output. Parte 1=terminal, Parte 2=web |
| `ascii.md` | 18 templates de representacao terminal | Default. Inline, rapido, sem dependencia. |
| `chrome.md` | Relay + Mermaid + HTML | Interativo, grandes, coloridos. Precisa relay. |
| `meta/obsidian` | Relatorios + Dataview | Artefatos persistentes no vault (skill separada). |

## Regra de decisao

```
Precisa de visualizacao?
    │
    ├── Cabe no terminal? (< 80 linhas, sem interacao)
    │     └─ usar ascii.md
    │
    ├── Precisa de interacao/cores/collapse? (arvores, diagramas grandes)
    │     └─ verificar relay → usar chrome.md
    │
    └── Precisa persistir como artefato? (relatorios, inspecoes)
          └─ usar meta/obsidian
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

### Chrome (relay) — inclui controle completo do browser
- Verificacao de disponibilidade + regra de decisao
- Comandos: nav, show, tabs, speak, present
- Diagrama Mermaid (flowchart com tema Catppuccin)
- Arvore de diff interativa (collapse, glow, breadcrumb)
- HTML livre (base64 → chrome-relay.py)
- Voz (espeak-ng via relay)

### Obsidian (vault)
- Relatorio de inspecao (frontmatter + findings)
- Dashboard Dataview (queries inline)
- Cards de agentes (frontmatter estruturado)
