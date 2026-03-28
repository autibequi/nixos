---
name: webview
description: "Tela de visualizacao no Chrome relay — flowcharts Mermaid com zoom/drag, arvores interativas, dashboards, HTML livre com CDN, ASCII art terminal, animacoes artisticas (eye, glados), voz, canvas colaborativo. Entrypoint para qualquer output visual."
---

# webview — Visualizacao e Arte Visual

Skill unificada para tudo visual: Chrome relay (Mermaid, diffs, dashboards, arte, voz), ASCII terminal, canvas colaborativo.

---

## Design System

**Ler `design-system.md` PRIMEIRO** — palette testada, tokens, emojis proibidos, regras de composicao.

## Sub-files

| Arquivo | Conteudo | Quando usar |
|---|---|---|
| `design-system.md` | Palette Catppuccin, tokens, box drawing | Sempre — antes de qualquer output |
| `ascii.md` | 19 templates de representacao terminal | Default. Sem dependencia. |
| `chrome.md` | Voz + templates artisticos (eye, glados) + canvas colaborativo | Arte no browser. Precisa relay. |
| `webview.md` | Detalhes do webview mode | Referencia |

---

## Regra de decisao

```
Precisa de visualizacao?
    |
    +-- e dado/flow/diagrama?
    |     +-- Cabe no terminal? (< 80 linhas)
    |     |     +- ascii.md
    |     +-- Precisa interacao (zoom, drag, click)?
    |           +- Mermaid / HTML no relay
    |
    +-- Arte no Chrome? (eye, glados, animacao, voz)
    |     +- chrome.md
    |
    +-- Diagrama colaborativo interativo? (user + eu iteramos juntos)
    |     +- chrome.md -> Canvas Colaborativo
    |
    +-- Precisa persistir no vault?
          +- obsidian skill
```

---

## Relay — Verificacao e Comandos

**Sempre fazer o live check antes de usar:**

```bash
python3 /workspace/self/scripts/chrome-relay.py status 2>&1
```

**Subir o servidor se nao estiver rodando:**
```bash
nohup python3 /workspace/self/scripts/chrome-relay.py serve > /tmp/relay-server.log 2>&1 &
```

**Regra de decisao:**
```
live check OK   -> usar normalmente
live check FAIL -> avisar: "Chrome nao responde — reiniciar relay?"
```

### Comandos

| Comando | O que faz |
|---------|-----------|
| `status` | Status do relay (Chrome + servidor) |
| `nav <url>` | Navega o Chrome para a URL |
| `show <arquivo.md>` | Serve markdown com Mermaid (zoom+drag automatico) |
| `tabs` | Lista abas abertas |
| `speak` | Fala via espeak-ng |
| `present` | Modo apresentacao |

---

## Flowchart Mermaid — uso rapido

O relay renderiza qualquer `.md` com blocos ` ```mermaid ``` ` fullscreen, sem containers aninhados.

```bash
python3 /workspace/self/scripts/chrome-relay.py show <arquivo.md>
```

**Layout default:**
- Fullscreen automatico — `100vw x 100vh`, sem `.page` container, sem bordas
- Diagrama centralizado no viewport ao carregar
- Auto-fullscreen do browser quando o `.md` tem so um diagrama
- Fundo liso `#0f0f12` direto — sem caixas dentro de caixas

Controles na tela:
- **Scroll** — zoom centrado no cursor
- **Click + drag** — pan
- **Reset** — aparece no hover (canto sup-dir), restaura posicao central
- **Pinch** — zoom em touch

---

## HTML Livre com CDN

Para visualizacoes custom, escrever HTML em `/tmp/chrome-relay/<nome>.html` e navegar:

```bash
python3 /workspace/self/scripts/chrome-relay.py nav "http://leech:8765/<nome>.html"
```

O relay serve arquivos estaticos de `/tmp/chrome-relay/` automaticamente.

### Bibliotecas CDN disponiveis

#### Diagramas
| Lib | CDN | Quando usar |
|-----|-----|-------------|
| **Mermaid** | `https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js` | Flowcharts, sequence, ER — use `show` em vez de HTML manual |
| **D3.js** | `https://cdn.jsdelivr.net/npm/d3@7` | Grafos, trees, layouts customizados |

#### Graficos / Dados
| Lib | CDN | Quando usar |
|-----|-----|-------------|
| **Chart.js** | `https://cdn.jsdelivr.net/npm/chart.js` | Linha, barra, pizza — metricas e logs |
| **Plotly** | `https://cdn.plot.ly/plotly-latest.min.js` | Graficos interativos (hover, zoom, pan) |

#### Tabelas
| Lib | CDN | Quando usar |
|-----|-----|-------------|
| **DataTables** | `https://cdn.datatables.net/1.13.7/...` | Tabelas com sort/filter — logs, issues |
| **Fuse.js** | `https://cdn.jsdelivr.net/npm/fuse.js@7` | Busca fuzzy client-side |

#### Diff / Codigo
| Lib | CDN | Quando usar |
|-----|-----|-------------|
| **diff2html** | `https://cdn.jsdelivr.net/npm/diff2html/bundles/...` | Render de git diff (side-by-side ou unificado) |
| **highlight.js** | `https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/...` | Syntax highlight |

#### UI
| Lib | CDN | Quando usar |
|-----|-----|-------------|
| **Tailwind CSS** | `https://cdn.tailwindcss.com` | Layout rapido |
| **Shoelace** | `https://cdn.jsdelivr.net/npm/@shoelace-style/shoelace@2/...` | Web components (tabs, cards) |

---

## Tema Catppuccin (copiar em qualquer HTML)

```css
:root {
  --ctp-base:     #1e1e2e;
  --ctp-mantle:   #181825;
  --ctp-surface0: #313244;
  --ctp-text:     #cdd6f4;
  --ctp-subtext0: #a6adc8;
  --ctp-green:    #a6e3a1;
  --ctp-blue:     #89b4fa;
  --ctp-peach:    #fab387;
  --ctp-red:      #f38ba8;
  --ctp-mauve:    #cba6f7;
  --ctp-yellow:   #f9e2af;
}
body {
  background: var(--ctp-base);
  color: var(--ctp-text);
  font-family: 'JetBrains Mono', monospace;
}
```

---

## Catalogo de visualizacoes

### Holodeck (relay)

| Visualizacao | Template | Descricao |
|---|---|---|
| **Flowchart Mermaid** | `templates/flowchart.md` | Qualquer diagrama — zoom/drag builtin, tema Catppuccin |
| **Code diff side-by-side** | `code/analysis/diff/codediff.md` | diff2html — linhas +/- com syntax highlight |
| **Arvore de diff interativa** | `code/analysis/diff/templates/interactive-tree.html` | Collapse, glow, breadcrumb |
| **Flow de codigo** | `code/analysis/flows/templates/html.md` | Mermaid read path + write path |
| **Dashboard custom** | CDN livre (Chart.js, D3, Plotly) | Qualquer grafico/tabela |

### ASCII (terminal) — 19 tipos

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
- 19 Stacked bar vertical / termometro (3 variantes)

### Chrome (relay) — arte e interacao

- Verificacao de disponibilidade + regra de decisao
- Comandos: nav, show, tabs, speak, present
- Mermaid fullscreen (zoom+drag, tema Catppuccin)
- Arvore de diff interativa (collapse, glow, breadcrumb)
- Code diff side-by-side (diff2html-cli dark + JetBrains Mono)
- Canvas colaborativo — diagramacao interativa user+eu em tempo real
  - API: `CANVAS.addNode/addEdge/addText/layout/state/clear`
  - Fluxo: abrir -> user manipula -> `CANVAS.state()` -> eu itero em cima
- HTML livre com CDN (diff2html, Chart.js, Mermaid, D3, DataTables...)
- Voz (espeak-ng via relay)

---

## Quando usar holodeck vs ASCII

| Criterio | ASCII | Holodeck (relay) |
|----------|-------|-----------------|
| Tamanho | < 80 linhas | > 80 linhas |
| Interacao | nenhuma | zoom, drag, click, hover |
| Velocidade | instantaneo | ~1s (relay) |
| Dependencia | nenhuma | relay ativo |
| Tipo | arte, esquemas simples | dados, flows, diagramas |

---

## Para agentes e skills externos

Se voce e um agente ou skill que precisa desenhar algo:

1. **NAO invente seu proprio formato** — consulte esta skill
2. Leia o sub-file do tipo de saida que precisa
3. Use os templates e convencoes documentados
4. Se criar um novo tipo de visualizacao que ficou bom, adicione aqui
