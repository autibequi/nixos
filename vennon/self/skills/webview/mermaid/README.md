# Template Mermaid (holodeck) — oficial

**Ficheiro canónico:** `base.html` (nesta pasta).

Espelho para compatibilidade de caminhos antigos:

- `skills/webview/templates/mermaid.html` — cópia; após editar `base.html`, executar:
  `cp skills/webview/mermaid/base.html skills/webview/templates/mermaid.html`

No workdir do projeto: `webview/mermaid/base.html` → ligação simbólica para este ficheiro (quando existir).

## Conteúdo

- `<title>`: **Mermaid live**; **sem barra superior** — só o diagrama e a pilha de controlos (canto inferior direito).
- Placeholder de geração: `MERMAID_DIAGRAM_HERE`
- **Drawer** esquerdo **Código** (textarea + Aplicar); pilha **+ / − / ⟳ / CODE / SVG / PNG / ⛶**; export **SVG** e **PNG**; indicador **verde «LIVE»** no canto quando o SSE está ligado; relay-ready (CSS/JS inline; Mermaid via CDN)
- **SSE:** o `base.html` liga a `/mermaid-live` por defeito (servidor **mermaid live**). **`?nolive=1`** desliga o EventSource se precisares de HTML estático sem servidor live.

## Colaboração agente + utilizador (regra de ouro)

1. **O utilizador vê no relay** — o agente **abre** o Chrome para o URL do holodeck (live ou estático), não só gera texto na conversa.
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

## Exemplo em Markdown

Ver `template/flow.md`. Para só diagrama em `.md` sem HTML, usar `chrome-relay.py show` (skill **webview**).

## Documentação completa

`skills/webview/SKILL.md` — secções **Pacote Mermaid** e **Mermaid Live — colaboração e relay**.
