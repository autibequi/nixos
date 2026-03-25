---
name: meta/holodeck
description: Tela de visualizacao no Chrome relay — flowcharts Mermaid com zoom/drag, arvores interativas, dashboards, HTML livre com CDN. Entrypoint para qualquer coisa que precisa ser renderizada como dado no browser.
---

# /meta:holodeck — Tela de Visualizacao

> O holodeck e a tela. Qualquer dado, diagrama ou flow que precise ser visto no Chrome passa por aqui.
> Para arte (eye, glados, animacoes): ver `meta/art`.

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
live check OK   → usar normalmente
live check FAIL → avisar: "Chrome nao responde — reiniciar relay?"
```

### Comandos

| Comando | O que faz |
|---------|-----------|
| `status` | Status do relay (Chrome + servidor) |
| `nav <url>` | Navega o Chrome para a URL |
| `show <arquivo.md>` | Serve markdown com Mermaid (zoom+drag automatico) |
| `tabs` | Lista abas abertas |
| `present` | Modo apresentacao |

---

## Catalogo de visualizacoes

Tudo que pode ser renderizado no holodeck:

| Visualizacao | Skill/Template | Descricao |
|---|---|---|
| **Flowchart Mermaid** | `holodeck/templates/flowchart.md` | Qualquer diagrama — zoom/drag builtin, tema Catppuccin |
| **Code diff side-by-side** | `code/analysis/diff/codediff.md` | diff2html — linhas +/- com syntax highlight, collapsible file list |
| **Arvore de diff interativa** | `code/analysis/diff/templates/interactive-tree.html` | Arvore de arquivos modificados — collapse, glow, breadcrumb |
| **Flow de codigo** | `code/analysis/flows/templates/html.md` | Mermaid read path + write path (handler→service→repo) |
| **Dashboard custom** | CDN livre (Chart.js, D3, Plotly) | Qualquer grafico/tabela com dados |

---

## Flowchart Mermaid — uso rapido

O relay renderiza qualquer `.md` com blocos ` ```mermaid ``` ` e ja injeta zoom/drag automaticamente.

```bash
python3 /workspace/self/scripts/chrome-relay.py show <arquivo.md>
```

Controles na tela:
- **Scroll** — zoom centrado no cursor
- **Click + drag** — arrastar o diagrama
- **⟳ reset** — aparece no hover (canto sup-dir)
- **Pinch** — zoom em touch

Ver template completo em `templates/flowchart.md`.

---

## HTML Livre com CDN

Para visualizacoes custom, escrever HTML em `/tmp/chrome-relay/<nome>.html` e navegar:

```bash
python3 /workspace/self/scripts/chrome-relay.py nav "http://127.0.0.1:8765/<nome>.html"
```

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

## Quando usar holodeck vs ASCII

| Criterio | ASCII (meta:art) | Holodeck |
|----------|-----------------|---------|
| Tamanho | < 80 linhas | > 80 linhas |
| Interacao | nenhuma | zoom, drag, click, hover |
| Velocidade | instantaneo | ~1s (relay) |
| Dependencia | nenhuma | relay ativo |
| Tipo | arte, esquemas simples | dados, flows, diagramas |
