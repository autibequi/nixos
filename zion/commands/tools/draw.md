# Draw — Servidor de desenho (Mermaid + Markdown no browser)

Use quando o usuário pedir diagramas no browser, "mostre no draw" ou quando Mermaid/Markdown rico for melhor que ASCII no terminal.

## Antes de desenhar
- **Levante o servidor ou verifique se está rodando.** Se a URL não abrir, inicie: `python3 /zion/scripts/draw-server.py &`
- **Sempre**, logo após levantar o servidor, diga ao usuário para abrir a página, por exemplo: *"Servidor no ar. Abra **http://localhost:8765** no browser para ver os desenhos."*

## URL
- **http://localhost:8765** — abrir no browser (no host; com `network_mode: host` a porta do container é a mesma).

## Conteúdo
- Escrever (Write) em **`/workspace/mnt/.zion-draw/content.md`** (ou `$WORKSPACE/.zion-draw/content.md`).
- A página faz polling a cada 2s e re-renderiza. Use blocos ` ```mermaid ` para diagramas e Markdown no resto.

## Iniciar o servidor
- Se a URL não abrir, iniciar em background no container:  
  `python3 /zion/scripts/draw-server.py &`
- Path do arquivo de conteúdo: env `ZION_DRAW_CONTENT` ou default `$WORKSPACE/.zion-draw/content.md`.

## Regra
- Quando o usuário estiver com a página aberta ou pedir saída no draw, usar essa página como output (escrever no arquivo e avisar que a página deve atualizar).
- Para referência de Mermaid e ASCII, usar a skill **draw** (`/workspace/zion/skills/tools/draw/` ou `~/.cursor/skills/tools/draw/`).
