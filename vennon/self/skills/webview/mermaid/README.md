# Template Mermaid (holodeck) — oficial

**Ficheiro canónico:** `base.html` (nesta pasta).

Espelho para compatibilidade de caminhos antigos:

- `skills/webview/templates/mermaid.html` — cópia; após editar `base.html`, executar:
  `cp skills/webview/mermaid/base.html skills/webview/templates/mermaid.html`

No workdir do projeto: `webview/mermaid/base.html` → ligação simbólica para este ficheiro (quando existir).

## Conteúdo

- Título fixo do gráfico: **Holodeck — base.html**
- Placeholders: `MERMAID_SUBTITLE_HERE`, `MERMAID_DIAGRAM_HERE`
- **Drawer** lateral esquerdo **Código** (com backdrop), zoom estilo mapa (+/−), export SVG, relay-ready (CSS/JS inline; Mermaid via CDN)

## Exemplo em Markdown

Ver `template/flow.md`. Para só diagrama em `.md` sem HTML, usar `chrome-relay.py show` (skill **webview**).

## Pré-visualização em tempo real (SSE)

1. Servidor (na pasta onde está o HTML a abrir, ou passa `--static`):

   `node skills/webview/mermaid/mermaid-live-server.mjs --file ./diagram.mmd --static . --port 9876`

2. Abrir no browser **o mesmo origin** (ex.: `http://127.0.0.1:9876/base.html?live=1`). O parâmetro `?live=1` liga `EventSource` a `/mermaid-live` e redesenha o diagrama quando o texto muda.

3. Atualizar o gráfico:
   - editar `diagram.mmd` no disco (o servidor usa `fs.watch`), ou
   - `curl -sS -X POST http://127.0.0.1:9876/mermaid-push --data-binary @diagram.mmd`

**Nota:** não funciona com `file://`; tem de ser HTTP. WebSocket também serve, mas aqui usámos SSE (menos dependências, um sentido servidor→cliente chega).

## Documentação completa

`skills/webview/SKILL.md` — secção **Pacote Mermaid**.
