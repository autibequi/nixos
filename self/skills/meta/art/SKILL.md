---
name: meta/art
description: Biblioteca central de representacoes visuais do Zion + controle do Chrome relay. 3 modos de saida (ASCII terminal, Chrome relay, Obsidian). Qualquer skill ou agente que precise desenhar algo ou usar o Chrome referencia esta skill.
---

# /meta:art — Biblioteca Visual do Zion

Skill composta com 3 sub-skills por tipo de saida. **Fonte da verdade** para qualquer representacao visual no sistema e para o controle do Chrome relay (CDP).

## Sub-skills

| Arquivo | Saida | Quando usar |
|---|---|---|
| `ascii.md` | Terminal | Sempre que possivel. Default. Inline, rapido, sem dependencia. |
| `chrome.md` | Chrome relay | Controle do browser (nav, show, tabs, speak) + templates visuais (Mermaid, arvore, HTML). Precisa relay ativo. |
| `obsidian.md` | Vault Obsidian | Relatorios persistentes, artefatos, dashboards Dataview. |

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
          └─ usar obsidian.md
```

## Para agentes e skills externos

Se voce e um agente ou skill que precisa desenhar algo:

1. **NAO invente seu proprio formato** — consulte esta skill
2. Leia o sub-file do tipo de saida que precisa
3. Use os templates e convencoes documentados
4. Se criar um novo tipo de visualizacao que ficou bom, adicione aqui

## Catalogo rapido (o que temos)

### ASCII (terminal)
- Fluxo de handler (mini-guia horizontal + deep-dive vertical)
- Mapa de caixas (black boxes com IN/OUT)
- Diagrama multi-path (read + write + guard)
- Logica interna (if/else, errgroup, loop, graceful degradation)
- Tabelas de status (ok/!!/XX)
- Graficos de barra horizontal
- Arvore de arquivos

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
