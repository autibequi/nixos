# Template Mermaid (holodeck) — oficial

**Ficheiro canónico:** `base.html` (nesta pasta).

Espelho para compatibilidade de caminhos antigos:

- `skills/webview/templates/mermaid.html` — cópia; após editar `base.html`, executar:
  `cp skills/webview/mermaid/base.html skills/webview/templates/mermaid.html`

No workdir do projeto: `webview/mermaid/base.html` → ligação simbólica para este ficheiro (quando existir).

## Conteúdo

- Título fixo do gráfico: **Holodeck — base.html**
- Placeholders: `MERMAID_SUBTITLE_HERE`, `MERMAID_DIAGRAM_HERE`
- Painel **Código**, zoom estilo mapa (+/−), export SVG, relay-ready (CSS/JS inline; Mermaid via CDN)

## Exemplo em Markdown

Ver `template/flow.md`. Para só diagrama em `.md` sem HTML, usar `chrome-relay.py show` (skill **webview**).

## Documentação completa

`skills/webview/SKILL.md` — secção **Pacote Mermaid**.
