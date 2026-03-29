# Template Mermaid (holodeck) — oficial

## Política (agentes — não negociável)

1. **Mostrar Mermaid ao utilizador** → **sempre** relay **live**: `mermaid_live_server.py` (ou `.mjs`) + **`base.html`** + `diagram.mmd` + `buzz("relay-nav", url="http://127.0.0.1:<porta>/base.html")`.
2. **Proibido** criar HTML/CSS/JS **novo** para embutir Mermaid; **só** o template canónico `base.html` (placeholder `MERMAID_DIAGRAM_HERE` ou push para `diagram.mmd`).
3. **`chrome-relay.py show` em `.md`** não substitui o fluxo live no ambiente vennon — ver `skills/webview/SKILL.md`.

**Ficheiro canónico:** `base.html` (nesta pasta).

Espelho para compatibilidade de caminhos antigos:

- `skills/webview/templates/mermaid.html` — cópia; após editar `base.html`, executar:
  `cp skills/webview/mermaid/base.html skills/webview/templates/mermaid.html`

No workdir do projeto: `webview/mermaid/base.html` → ligação simbólica para este ficheiro (quando existir).

## Galeria (todos os templates numa página)

- **`gallery-all.html`** — página estática com **todos** os diagramas dos `template/*.md` (incl. `flow-subgraphs`), empilhados. Serve para **ver tudo de uma vez** e exportar **uma imagem** (Chrome DevTools → *Capture full size screenshot*) ou **PDF** (Imprimir). Abrir no mesmo servidor que serve esta pasta, ex.: `http://127.0.0.1:9876/gallery-all.html`. **Não** substitui o holodeck live (`base.html` + `diagram.mmd`).

- **`monolito-multi-tabs.html`** — **cinco abas**, cada uma com um **tipo Mermaid diferente** (flowchart+subgraph, sequence, class, state, ER), todos com narrativa centrada no **monolito**. Comparação rápida entre tipos; cada diagrama só renderiza ao abrir a aba (evita problemas com `display:none`). URL típica: `http://127.0.0.1:9876/monolito-multi-tabs.html`.

## Conteúdo

- `<title>`: **Mermaid live**; **sem barra superior** — só o diagrama e a pilha de controlos (canto inferior direito).
- Placeholder de geração: `MERMAID_DIAGRAM_HERE`
- **Drawer** esquerdo **Código** (textarea + Aplicar); pilha **+ / − / ⟳ / CODE / SVG / ⛶**; export **SVG**; indicador **verde «LIVE»** no canto quando o SSE está ligado; relay-ready (CSS/JS inline; Mermaid via CDN)
- **SSE:** o `base.html` liga a `/mermaid-live` por defeito (servidor **mermaid live**). **`?nolive=1`** desliga o EventSource se precisares de HTML estático sem servidor live.

## Colaboração agente + utilizador (regra de ouro)

1. **O utilizador vê no relay** — o agente **abre** o Chrome no URL do **live** (`base.html` no servidor Mermaid live), não só gera texto na conversa.
2. **Estado atual** — antes de **cada** alteração ao desenho, o agente **lê** o que está mesmo no browser:
   - preferência: `buzz("relay-inject", ...)` no textarea `#hk-mermaid-ta` (e SVG se precisar);
   - o utilizador pode ter mudado o diagrama no drawer **sem** gravar o `diagram.mmd` no disco.
3. **Edição** — aplicar mudanças **em cima** do texto lido, nunca sobrescrever o fluxo inteiro só com base na memória do chat.
4. **Empurrar** — gravar em `diagram.mmd` e `POST /mermaid-push` (ou confiar no `fs.watch` se só editaste o ficheiro).

Documentação alinhada: **`skills/webview/SKILL.md`** — secção **Mermaid Live — colaboração e relay**.

## Pré-visualização em tempo real (SSE)

**Servidor recomendado no container** (Python, sem Node):

```bash
python3 skills/webview/mermaid/mermaid_live_server.py \
  --file ./diagram.mmd --static . --port 9876 --bind 127.0.0.1
```

**Variante Node** (se existir `node`):

```bash
node skills/webview/mermaid/mermaid-live-server.mjs --file ./diagram.mmd --static . --port 9876
```

1. Abrir no browser **o mesmo origin** que o servidor: `http://127.0.0.1:9876/base.html`.
2. Atualizar o gráfico:
   - editar `diagram.mmd` no disco (polling de mtime no servidor Python), ou
   - `curl -sS -X POST http://127.0.0.1:9876/mermaid-push --data-binary @diagram.mmd`
3. Abrir no relay: `buzz("relay-nav", url="http://127.0.0.1:9876/base.html")` (requer `127.0.0.1:PORT` alcançável pelo Chrome do host — típico com `network_mode: host`).

**Nota:** não funciona com `file://`. O relay clássico (`chrome-relay.py` + `/tmp/chrome-relay/`) serve HTML estático; o **live** usa **outra porta** (ex. 9876) com o servidor acima.

## Exemplos em Markdown (catálogo)

- **Índice completo** de tipos de diagrama e ficheiros: **`template/README.md`** (flowchart, sequence, state, class, ER, journey, gantt, pie, gitGraph, mindmap, timeline, quadrant, requirement, sankey, xychart, architecture-beta, block-beta, packet, C4×5, ZenUML).
- **Estilos transversais** (tema, `classDef`, imagens, limites): **`styling-global.md`**.

Para só diagrama em `.md` sem HTML, usar `chrome-relay.py show` (skill **webview**) — um ficheiro por tipo em `template/*.md`.

## Documentação completa

`skills/webview/SKILL.md` — secções **Pacote Mermaid** e **Mermaid Live — colaboração e relay**.
