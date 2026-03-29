---
name: webview/mermaid/template/flow
description: Exemplo de flowchart Mermaid para usar com base.html (placeholders) ou com chrome-relay show.
---

# Exemplo — Flowchart

Copie o bloco `mermaid` para o placeholder `MERMAID_DIAGRAM_HERE` em `mermaid/base.html`, ou guarde este ficheiro e use:

```bash
python3 /workspace/self/scripts/chrome-relay.py show /workspace/self/skills/webview/mermaid/template/flow.md
```

## Diagrama (Catppuccin / pipeline)

```mermaid
%%{init: {'theme': 'dark'}}%%
flowchart TD
  A([Entrada]) --> B{Decisão}
  B -->|sim| C[Fluxo A]
  B -->|não| D[Fluxo B]
  C --> E([Saída])
  D --> E

  style A fill:#cba6f7,color:#1e1e2e
  style E fill:#a6e3a1,color:#1e1e2e
  style C fill:#89b4fa,color:#1e1e2e
  style D fill:#fab387,color:#1e1e2e
```

## Placeholders no `base.html`

O nome do gráfico na barra é fixo: **Holodeck — base.html** (título e `document.title`).

| Placeholder | Exemplo |
|-------------|---------|
| `MERMAID_SUBTITLE_HERE` | Card XYZ · branch `feature/foo` (ou vazio para ocultar) |
| `MERMAID_DIAGRAM_HERE` | o bloco `flowchart TD` acima (sem fences) |

Para HTML gerado a partir deste `.md`, substitua `MERMAID_SUBTITLE_HERE` por texto real ou deixe vazio para ocultar a linha.
