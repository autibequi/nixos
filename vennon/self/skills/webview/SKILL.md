---
name: webview
description: "Mostrar no relay — abrir conteudo no Chrome (HTML, Mermaid, diff, imagens) via chrome-relay e buzz. Mermaid holodeck live (SSE + POST): cooperacao com o utilizador; antes de editar o desenho, ler estado atual com relay-inject (textarea/SVG), nao so memoria do chat. Alternativa sem browser: ASCII (ascii.md)."
---

# webview — Mostrar no relay

**O que é:** levar qualquer coisa **visual** para o **browser do usuário** usando o **relay** (`chrome-relay.py` no container + Chrome/CDP + HTTP local, e opcionalmente **buzz** no host). Não confundir com o orquestrador de containers — aqui só importa **mostrar no relay**.

**Chrome do relay:** o default inclui flags para **não** oferecer tradução automática e **não** mostrar o bubble de “restaurar páginas” (`RELAY_CHROME_FLAGS` no `chrome-relay.py`; `relay-start` no buzz usa o mesmo par de flags). Override com `export RELAY_CHROME_FLAGS='...'` se precisar.

Também cobre **ASCII no terminal** quando não precisa de browser — ver `ascii.md`, `design-system.md`, `chrome.md` (arte/voz).

---

## Design System

**Ler `design-system.md` PRIMEIRO** — palette testada, tokens, emojis proibidos, regras de composicao.

## Templates webview (HTML) — um único arquivo

Sempre que você criar um **template** ou página HTML para o relay:

- **Todo o HTML, todo o CSS e todo o JS** entram no **mesmo ficheiro `.html`**: `<style>...</style>` e `<script>...</script>` inline no documento. **Não** gerar `foo.css` / `foo.js` / `foo.html` separados (evita 404, ordem de load e paths errados).
- **Exceção**: bibliotecas via **CDN** (`<script src="https://...">`, `<link href="https://...">`) — são dependências remotas, não ficheiros locais extra.
- **Imagens**: preferir **data URI** em base64 no próprio HTML para ficar tudo num só ficheiro; só usar `src="imagem.png"` ao lado se o binário for grande e o utilizador aceitar dois ficheiros na mesma pasta.

O mesmo vale para `data:text/html;base64,...` no `nav`: o documento decodificado deve ser **autocontido** da mesma forma.

## Pacote Mermaid (`mermaid/`)

| Ficheiro | Função |
|----------|--------|
| `mermaid/base.html` | **Fonte canónica** — título fixo **Holodeck — base.html**; diagrama fullscreen, zoom (scroll), pan, pinch, botões **+ / −** (canto inferior direito, estilo mapa), indicador %, **drawer** lateral esquerdo **Código** (textarea + Aplicar, backdrop clicável), SVG/Reset/ecrã inteiro, `Esc` fecha o drawer, atalhos `R` `+` `-` `0` `F`, duplo clique = reset, `prefers-reduced-motion`, `aria-label` nos botões. Placeholders: `MERMAID_SUBTITLE_HERE`, `MERMAID_DIAGRAM_HERE`. **Nota:** Mermaid não permite arrastar nós/setas no SVG; edição é por texto (drawer) ou outra ferramenta (Excalidraw, draw.io). |
| `mermaid/template/flow.md` | Exemplo de flowchart + instruções para `show` ou para colar no `base.html`. |
| `templates/mermaid.html` | Cópia espelhada de `base.html` (atualizar com `cp` após mudanças no base). |

Atalhos (com foco na página, fora de inputs): **Esc** fecha o drawer de código, **R** reset, **+** / **=** zoom in, **-** zoom out, **0** fit, **F** ecrã inteiro. **Duplo clique** na área do diagrama = reset. O **Código** abre o drawer lateral (botão na barra ou backdrop para fechar).

**HTML:** não usar comentários `<!-- ... -->` longos com `<`, `</`, `&lt;porta&gt;` ou `--` no meio — o parser pode fechar o comentário cedo e o restante aparece como texto antes do header (layout partido). Documentação fica na SKILL, não em comentários no `.html`.

Relay: `cp mermaid/base.html /tmp/chrome-relay/foo.html` → abrir `http://vennon:<porta>/foo.html` (porta em `chrome-relay.py status`).

No workdir do repositório (`/workspace/target`), `webview/mermaid/base.html` e `webview/mermaid/template/flow.md` são **ligações simbólicas** para os mesmos ficheiros em `self/skills/webview/mermaid/`.

## Sub-files

| Arquivo | Conteudo | Quando usar |
|---|---|---|
| `design-system.md` | Palette Catppuccin, tokens, box drawing | Sempre — antes de qualquer output |
| `ascii.md` | 19 templates de representacao terminal | Default. Sem dependencia. |
| `chrome.md` | Voz + templates artisticos (eye, glados) + canvas colaborativo | Arte no browser. Precisa relay. |
| `webview.md` | Detalhes do webview mode | Referencia |
| `mermaid/base.html` | HTML único holodeck Mermaid (toolbar + atalhos + export) | Base para diagramas no relay; ver secção **Pacote Mermaid** |
| `mermaid/template/flow.md` | Exemplo flowchart | Copiar bloco mermaid ou usar com `show` |
| `mermaid/README.md` | **Template oficial** — resumo, live SSE, colaboração | Ao orientar agentes ou devs sobre qual ficheiro editar |
| `mermaid/mermaid_live_server.py` | Servidor HTTP + SSE + `POST /mermaid-push` (stdlib Python) | Colaboração em tempo real com `base.html?live=1` |
| `mermaid/mermaid-live-server.mjs` | Variante Node (mesma API) | Se `node` existir no ambiente |

---

## Mermaid Live — colaboração e relay (obrigatório para fluxos iterativos)

**Ideia:** o diagrama é **ferramenta partilhada** — o utilizador vê no Chrome (relay), pode editar no drawer **Código** ou receber atualizações por SSE; o agente **nunca** assume o desenho só pela memória do chat.

### Iniciativa do agente

1. Quando o pedido for **mostrar um diagrama Mermaid no relay** *e* houver intenção de **iterar, cooperar ou “ir mexendo”** — preferir o **holodeck live** (`base.html?live=1` + servidor `mermaid_live_server.py`), não apenas copiar HTML estático para `/tmp/chrome-relay/` (esse modo é one-shot, sem sincronização contínua).
2. Quando o pedido for genérico do tipo **“mostra no relay …”** (árvore, fluxo, organograma) — **abrir o relay** com o Mermaid já gerado: subir ou reutilizar o live, gravar o código, **POST**, **relay-nav** para a URL live (ver pipeline abaixo).

### Estado atual — ler antes de editar (não negociável)

- **Fonte de verdade na aba live:** usar **`buzz("relay-inject", js=...)`** para ler o código atual, por exemplo o textarea do holodeck:
  - `document.getElementById('hk-mermaid-ta')` → `.value` (texto Mermaid completo).
  - Se vazio ou inexistente, complementar com texto dos nós no **SVG** (`document.querySelectorAll('.mermaid svg text')` e `foreignObject`).
- **Fonte no disco:** se o servidor live estiver a servir `diagram.mmd`, podes ler esse ficheiro — mas se o utilizador tiver alterado **só no browser** (drawer **Aplicar**), o disco pode estar desatualizado; **inject na aba live ganha** quando a URL for `.../base.html?live=1`.
- **Proibido:** reescrever o diagrama completo com base **apenas** no histórico da conversa. Sempre: **ler estado atual → aplicar alterações em cima disso**.

### Pipeline — abrir e manter o live (referência rápida)

1. **Relay pronto:** `python3 /workspace/self/scripts/chrome-relay.py status` → se CDP OFF, `buzz("relay-start")` (ver secção **Relay — fluxo único**).
2. **Servidor Mermaid Live** (em background, se ainda não estiver na porta desejada):

   ```bash
   python3 /workspace/self/skills/webview/mermaid/mermaid_live_server.py \
     --file /workspace/self/skills/webview/mermaid/diagram.mmd \
     --static /workspace/self/skills/webview/mermaid \
     --port 9876 --bind 127.0.0.1
   ```

   (Ajustar `--file` / `--static` ao workdir do utilizador; **mesma pasta** para `base.html` e `diagram.mmd`.)

3. **Gravar o diagrama** em `diagram.mmd` (texto Mermaid completo) e **empurrar** para o browser:

   ```bash
   curl -sS -X POST http://127.0.0.1:9876/mermaid-push --data-binary @/caminho/diagram.mmd
   ```

4. **Abrir no Chrome** (host com rede compatível com `127.0.0.1:9876`; em setups vennon com `network_mode: host` costuma funcionar):

   ```text
   buzz("relay-nav", url="http://127.0.0.1:9876/base.html?live=1")
   ```

5. **Iterações seguintes:** antes de cada alteração, **relay-inject** (textarea/SVG) → editar → gravar `diagram.mmd` → **POST** outra vez (o SSE atualiza a aba sem fechar a janela).

### Exemplo de pedido em linguagem natural

- *“Mostra no relay a árvore do presidente e ministros atuais”* — pesquisar ou estruturar dados → gerar bloco `flowchart`/`graph` Mermaid válido → escrever `diagram.mmd` → `mermaid-push` → `relay-nav` para `base.html?live=1`. Próximos refinamentos: **sempre** ler estado com inject antes de mudar.

### Live vs HTML estático no `/tmp/chrome-relay`

| Modo | Quando |
|------|--------|
| **`base.html?live=1` + `mermaid_live_server.py`** | Cooperação, edição pelo utilizador, iterar com o agente sem drift de estado |
| **`cp base.html /tmp/chrome-relay/foo.html` + `nav`** | Uma visualização pontual, sem SSE |

Detalhes extra e notas sobre Node vs Python: `mermaid/README.md`.

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
    +-- Diagrama Mermaid iterativo / "mostra no relay" com cooperação?
    |     +- mermaid_live_server.py + base.html?live=1 + relay-inject (esta skill)
    +-- Diagrama colaborativo interativo? (user + eu iteramos juntos)
    |     +- chrome.md -> Canvas Colaborativo
    |
    +-- Precisa persistir no vault?
          +- obsidian skill
```

---

## Relay — fluxo único (agentes no container)

### Iniciativa — abrir o relay sem pedir permissão

Quando você for **mostrar algo no Chrome** (HTML, Mermaid, diff, imagem, dashboard):

1. **Não pergunte** ao usuário se pode “ligar o relay” ou “abrir o Chrome”. É sua responsabilidade deixar o ambiente pronto.
2. Rode `python3 /workspace/self/scripts/chrome-relay.py status`. Se **Chrome CDP: OFF**, chame **`buzz("relay-start")`** (cliente Python no socket — ver **buzz**) e rode `status` de novo. Só então use `nav`, `show`, `inject`.
3. Se **Content server: OFF** e você precisar servir arquivos em `/tmp/chrome-relay/`, **suba o servidor por conta própria**: `nohup python3 /workspace/self/scripts/chrome-relay.py serve >>/tmp/chrome-relay/serve.log 2>&1 &` (ou um `show` de qualquer `.md` mínimo) e confira `status` — sem pedir confirmação.
4. Se após `relay-start` o CDP continuar OFF (falha real no host), **aí sim** explique em uma frase o que falhou; não fique tentando à cega.

Resumo: **iniciativa = status → subir o que faltar → mostrar conteúdo**. O usuário pediu visualização; executar o pipeline é o esperado.

---

**1. Checagem obrigatória** (CDP + servidor HTTP + URL pública):

```bash
python3 /workspace/self/scripts/chrome-relay.py status
```

Use a linha **`Public base:`** como URL raiz (e `RELAY_HTTP_HOST` se precisar ajustar hostname). O default do script é um hostname configurável por env; se o Chrome não resolver, `export RELAY_HTTP_HOST=127.0.0.1` (ou o host que o browser alcançar).

**2. Se Chrome CDP estiver OFF** (já deveria ter sido tratado na iniciativa acima)

- **`buzz("relay-start")`** — preferido no container.
- Fallback: `python3 /workspace/self/scripts/chrome-relay.py start` mostra o comando Chromium com `--remote-debugging-port=9222` para rodar no host.

Se o container **não** enxergar `localhost:9222`, o CDP não funciona com `chrome-relay.py` até haver rede/port-forward adequados; nesse caso use **só buzz** para `relay-nav` / `relay-show`.

**3. Escolha da ferramenta**

| Ferramenta | Quando |
|------------|--------|
| `chrome-relay.py` | CDP OK no container; controle direto (nav, show, inject, status). |
| `buzz` + `relay-*` | Subir relay no host, paths validados pelo daemon, sem depender de CDP local. |

**4. Conteúdo estático (HTML, imagens, JSON)**

- Diretório servido: **`/tmp/chrome-relay/`** (ou `RELAY_CONTENT_DIR`). Arquivos são expostos como `<Public base><basename>` (ex.: `.../pagina.html`).
- Porta: **8765–8768** (primeira livre). **Não fixe uma porta** às cegas — use a linha **`Public base:`** de `status` (ou `Content server: OK (:PORTA)`).
- **Não** use `python3 -m http.server` nas portas **8765–8768**. Outro processo nessa faixa fazia o relay “parecer” ativo na porta errada e o Chrome recebia **404** mesmo com o arquivo em `/tmp/chrome-relay/` (o servidor do `chrome-relay.py` é identificado por `GET /health` → `{"ok":true}`).
- Servidor **persistente**: `nohup python3 /workspace/self/scripts/chrome-relay.py serve >>/tmp/chrome-relay/serve.log 2>&1 &` e confira `status`. O comando `show` sobe HTTP em thread daemon e o processo pode encerrar em seguida — para HTML estático, prefira `serve` em background.
- Se **Content server OFF**: suba com `serve` em background ou um `show` de qualquer `.md` mínimo.
- Navegar: `nav` com **`Public base` + nome do arquivo** (copiar a URL de `status`, não inventar host/porta).

**5. HTML pequeno sem servidor**

Use `data:text/html;base64,...` com `nav` (ver skill `code/report` e `code/analysis/flows`).

### buzz — mesmas ações (socket Python, não `buzz call`)

| Action | Função |
|--------|--------|
| `relay-status` | Relay no host |
| `relay-start` / `relay-stop` | Chrome + relay |
| `relay-nav` + `url=` | Navega |
| `relay-show` + `path=` | Markdown/Mermaid |
| `relay-tabs` | Abas |
| `relay-inject` + `js=` | JS na aba |

Detalhes: **`skills/buzz/SKILL.md`**.

---

## Flowchart Mermaid — uso rapido

O relay renderiza qualquer `.md` com blocos ` ```mermaid ``` ` fullscreen, sem containers aninhados.

```bash
python3 /workspace/self/scripts/chrome-relay.py show /tmp/meu-flow.md
```

Ou via buzz (Python): `buzz("relay-show", path="/tmp/meu-flow.md")`.

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

1. `mkdir -p /tmp/chrome-relay`
2. Escrever **`pagina.html` único** (HTML + CSS + JS inline — ver **Templates webview** acima); CDN só para libs.
3. `python3 /workspace/self/scripts/chrome-relay.py status` — copiar **`Public base`** e montar `<Public base>pagina.html`
4. `python3 /workspace/self/scripts/chrome-relay.py nav "<URL completa>"`

O servidor HTTP escuta em `127.0.0.1`; o hostname nas URLs vem de `RELAY_HTTP_HOST` (veja `status`).

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

### No relay (browser)

| Visualizacao | Template | Descricao |
|---|---|---|
| **Flowchart Mermaid** | `templates/flowchart.md` | Qualquer diagrama — zoom/drag builtin, tema Catppuccin |
| **Mermaid holodeck (HTML único)** | `mermaid/base.html` | Toolbar, zoom, código, export SVG, ecrã inteiro — ver **Pacote Mermaid** |
| **Exemplo flow .md** | `mermaid/template/flow.md` | Flowchart de exemplo + uso com `show` |
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

### Relay — arte e interacao

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

## Quando usar relay vs ASCII

| Criterio | ASCII | Relay (browser) |
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
2. **Templates HTML no relay:** um único `.html` com CSS e JS inline (secção **Templates webview**)
3. Leia o sub-file do tipo de saida que precisa
4. Use os templates e convencoes documentados
5. Se criar um novo tipo de visualizacao que ficou bom, adicione aqui

### Abrir o Chrome (dependencia do relay)

1. `python3 /workspace/self/scripts/chrome-relay.py status`
2. Se CDP OFF: skill **buzz** com `relay-start`, ou Chrome no host com `--remote-debugging-port=9222`
3. `chrome-relay.py show|nav|inject` **ou** `buzz("relay-show", ...)` / `buzz("relay-nav", url=...)`

Leia `skills/buzz/SKILL.md` para o cliente socket e validações.

### Copia desta skill no Cursor

Fonte: `/workspace/self/skills/webview/`. Se o editor espelhar para `~/.cursor/skills/`, sincronize após editar a fonte.
