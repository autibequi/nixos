---
name: code/analysis/flows/html-template
description: Template HTML com Mermaid CDN e tema Catppuccin Mocha para renderizar diagramas de fluxo no Chrome via chrome-relay.py
---

# Template HTML — Flows Diagram

Substituir `{{BRANCH_NAME}}`, `{{READ_PATH_DIAGRAM}}`, `{{WRITE_PATH_DIAGRAM}}` ao gerar.

Para diagrama único (--modo leitura ou --modo escrita), omitir a seção não usada.

```html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Flows — {{BRANCH_NAME}}</title>
<script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
<style>
  :root {
    --ctp-base: #1e1e2e;
    --ctp-mantle: #181825;
    --ctp-crust: #11111b;
    --ctp-surface0: #313244;
    --ctp-surface1: #45475a;
    --ctp-overlay0: #6c7086;
    --ctp-text: #cdd6f4;
    --ctp-subtext0: #a6adc8;
    --ctp-green: #a6e3a1;
    --ctp-blue: #89b4fa;
    --ctp-peach: #fab387;
    --ctp-red: #f38ba8;
    --ctp-mauve: #cba6f7;
    --ctp-yellow: #f9e2af;
    --ctp-teal: #94e2d5;
  }

  * { box-sizing: border-box; margin: 0; padding: 0; }

  body {
    background: var(--ctp-base);
    color: var(--ctp-text);
    font-family: 'JetBrains Mono', 'Fira Code', monospace;
    padding: 2rem;
    min-height: 100vh;
  }

  header {
    border-bottom: 1px solid var(--ctp-surface1);
    padding-bottom: 1rem;
    margin-bottom: 2rem;
  }

  header h1 {
    font-size: 1.4rem;
    color: var(--ctp-mauve);
    letter-spacing: 0.05em;
  }

  header .branch-name {
    display: inline-block;
    background: var(--ctp-surface0);
    color: var(--ctp-green);
    padding: 0.2rem 0.7rem;
    border-radius: 4px;
    font-size: 0.85rem;
    margin-top: 0.4rem;
  }

  .section {
    margin-bottom: 3rem;
  }

  .section-title {
    font-size: 0.9rem;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    color: var(--ctp-subtext0);
    margin-bottom: 1rem;
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .section-title .dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    display: inline-block;
  }

  .read-dot  { background: var(--ctp-blue); }
  .write-dot { background: var(--ctp-peach); }

  .diagram-box {
    background: var(--ctp-mantle);
    border: 1px solid var(--ctp-surface0);
    border-radius: 8px;
    padding: 1.5rem;
    overflow-x: auto;
  }

  .legend {
    margin-top: 2rem;
    padding: 1rem;
    background: var(--ctp-mantle);
    border-radius: 6px;
    border: 1px solid var(--ctp-surface0);
    font-size: 0.8rem;
    color: var(--ctp-subtext0);
  }

  .legend-row {
    display: flex;
    gap: 2rem;
    flex-wrap: wrap;
  }

  .legend-item {
    display: flex;
    align-items: center;
    gap: 0.4rem;
  }

  .legend-swatch {
    width: 14px;
    height: 14px;
    border-radius: 3px;
  }

  .mermaid { text-align: center; }
</style>
</head>
<body>
<header>
  <h1>Flows Diagram</h1>
  <span class="branch-name">{{BRANCH_NAME}}</span>
</header>

<div class="section">
  <div class="section-title">
    <span class="dot read-dot"></span>
    Read Path
  </div>
  <div class="diagram-box">
    <div class="mermaid">
%%{init: {'theme': 'base', 'themeVariables': {
  'primaryColor': '#313244',
  'primaryTextColor': '#cdd6f4',
  'primaryBorderColor': '#45475a',
  'lineColor': '#6c7086',
  'secondaryColor': '#181825',
  'tertiaryColor': '#11111b',
  'background': '#1e1e2e',
  'mainBkg': '#313244',
  'nodeBorder': '#45475a',
  'clusterBkg': '#181825',
  'titleColor': '#cdd6f4',
  'edgeLabelBackground': '#1e1e2e'
}}}%%
{{READ_PATH_DIAGRAM}}
    </div>
  </div>
</div>

<div class="section">
  <div class="section-title">
    <span class="dot write-dot"></span>
    Write Path
  </div>
  <div class="diagram-box">
    <div class="mermaid">
%%{init: {'theme': 'base', 'themeVariables': {
  'primaryColor': '#313244',
  'primaryTextColor': '#cdd6f4',
  'primaryBorderColor': '#45475a',
  'lineColor': '#6c7086',
  'secondaryColor': '#181825',
  'tertiaryColor': '#11111b',
  'background': '#1e1e2e',
  'mainBkg': '#313244',
  'nodeBorder': '#45475a',
  'clusterBkg': '#181825',
  'titleColor': '#cdd6f4',
  'edgeLabelBackground': '#1e1e2e'
}}}%%
{{WRITE_PATH_DIAGRAM}}
    </div>
  </div>
</div>

<div class="legend">
  <div class="legend-row">
    <div class="legend-item">
      <div class="legend-swatch" style="background:#a6e3a1"></div>
      <span>Novo (★)</span>
    </div>
    <div class="legend-item">
      <div class="legend-swatch" style="background:#89b4fa"></div>
      <span>Cache / Redis</span>
    </div>
    <div class="legend-item">
      <div class="legend-swatch" style="background:#fab387"></div>
      <span>Trigger / Queue</span>
    </div>
    <div class="legend-item">
      <div class="legend-swatch" style="background:#f38ba8"></div>
      <span>Erro / Conflito</span>
    </div>
  </div>
</div>

<script>
  mermaid.initialize({
    startOnLoad: true,
    theme: 'base',
    securityLevel: 'loose'
  })
</script>
</body>
</html>
```

## Como gerar e abrir

```bash
# 1. Escrever HTML em /tmp/flows.html
# 2. Encodar em base64 e abrir no Chrome
HTML_B64=$(base64 -w 0 /tmp/flows.html)
python3 /workspace/zion/scripts/chrome-relay.py nav "data:text/html;base64,${HTML_B64}"
```
