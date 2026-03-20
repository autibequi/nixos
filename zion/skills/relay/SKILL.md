---
name: relay
description: Controle total do Chrome do usuario via CDP. Navegar URLs, servir Mermaid/Markdown, injetar JS, gerar visualizacoes. O agent deve ser PROATIVO — usar o Chrome para mostrar coisas sem esperar o usuario pedir.
trigger: proactive
---

# Chrome Relay — Skill

## O que e

O agent tem controle total de uma sessao Chrome no host via CDP (Chrome DevTools Protocol).
Isso significa: navegar pra qualquer URL, servir paginas locais com Mermaid/Markdown, injetar JavaScript, e usar o browser como uma tela de output rico.

## Pre-requisito

Chrome rodando no host com `--remote-debugging-port=9222`.
Verificar: `python3 /zion/scripts/chrome-relay.py status`

## Script

`/zion/scripts/chrome-relay.py` — arquivo unico, sem dependencias externas.

| Comando | O que faz |
|---------|-----------|
| `nav <url>` | Navega o Chrome pra URL |
| `show <file.md>` | Serve arquivo markdown e navega Chrome pra ele |
| `inject <js>` | Executa JavaScript na aba ativa |
| `tabs` | Lista abas abertas |
| `serve [--once]` | Sobe servidor de conteudo (http://zion:8765) |
| `status` | Verifica Chrome CDP + servidor |

## Comportamento PROATIVO

**O agent NAO deve esperar o usuario pedir pra usar o Chrome.** Deve tomar iniciativa sempre que julgar que uma visualizacao ajuda.

### Quando usar automaticamente:

1. **Explicando algo complexo** — gerar Mermaid (flowchart, sequence, mindmap, timeline) e mostrar no Chrome
2. **Mostrando dados** — tabelas, comparacoes, metricas do Grafana
3. **Investigando logs/erros** — correlacionar com dashboards e mostrar
4. **Code review** — gerar diagrama de dependencias ou fluxo
5. **Qualquer momento** em que ASCII no terminal nao e suficiente

### Liberdade artistica:

- Escolher o tipo de diagrama que melhor representa a informacao
- Combinar Mermaid + Markdown + tabelas numa mesma pagina
- Usar cores, agrupamentos, e hierarquias visuais
- Criar paginas multi-secao quando o conteudo justificar
- Navegar pra sites externos quando relevante (docs, PRs, dashboards)

## Autonomia sobre janela e abas

O agent tem liberdade total para gerenciar o Chrome sem pedir permissao:

- **Criar abas** — quando precisar mostrar algo sem perder o que o usuario esta vendo
- **Fechar abas** — ao terminar de usar uma aba criada por ele
- **Trocar aba ativa** — para focar o usuario no conteudo certo
- **Maximizar janela** — quando o conteudo for grande (diagramas, diffs, tabelas densas)
- **Restaurar para maximized** — quando o conteudo for pequeno ou ja foi consumido
- **Fullscreen** — apenas se o usuario pedir explicitamente

### Regra de tamanho de conteudo:

| Conteudo | Estado da janela |
|----------|-----------------|
| Diagrama grande, diff, relatorio denso | `fullscreen` ou `maximized` |
| Pagina normal, docs, resultado simples | `maximized` (padrao) |
| Saindo do fullscreen | `normal` → `maximized` (dois passos, CDP exige) |

### Gestao de abas — filosofia:

Por padrao, **reusar a aba ativa** (recarregar com novo conteudo). So criar aba nova quando:
- O usuario pede explicitamente
- Precisa preservar algo que o usuario esta vendo
- Vai mostrar dois conteudos em paralelo

Para **trocar o foco** pra uma aba especifica, usar `Page.bringToFront` via CDP:

```python
ws_send(sock, json.dumps({'id':1,'method':'Page.bringToFront'}))
```

Para **navegar em aba especifica** (nao a ativa), conectar via `webSocketDebuggerUrl` da aba alvo em `/json` e usar `Page.navigate`.

## Como servir conteudo local

1. Escrever markdown (com blocos ```mermaid```) em arquivo temporario
2. Usar `chrome-relay.py show <arquivo>` — ele:
   - Sobe servidor HTTP automaticamente
   - Navega o Chrome pra http://zion:8765
   - A pagina renderiza Mermaid + Markdown com tema dark
   - Live reload via SSE (se editar o arquivo, atualiza sozinho)

## Como navegar pra URL externa

```bash
python3 /zion/scripts/chrome-relay.py nav "https://grafana.example.com/d/uid"
```

## Como injetar JavaScript

```bash
python3 /zion/scripts/chrome-relay.py inject "document.title"
python3 /zion/scripts/chrome-relay.py inject "document.querySelector('h1').textContent"
```

## Controle de janela e abas via CDP direto

Algumas operacoes nao tem comando no script — usar CDP REST ou WebSocket diretamente.

### Abrir nova aba

```bash
curl -s -X PUT "http://localhost:9222/json/new?about:blank"
# Retorna JSON com o id da nova aba
```

### Fullscreen / Maximizar / Restaurar

Requer WebSocket com Browser.setWindowBounds. **Regra importante:** para sair do fullscreen, passar por `normal` antes de ir pra `maximized` — o CDP rejeita a transicao direta.

```python
# Sequencia correta para ENTRAR em fullscreen:
#   windowState: "fullscreen"

# Sequencia correta para SAIR do fullscreen:
#   1. windowState: "normal"
#   2. windowState: "maximized"
```

Script reutilizavel (salvar em /tmp/cdp_window.py ou copiar inline):

```python
import urllib.request, json, socket, os, base64, struct
from urllib.parse import urlparse

def cdp_get(path):
    return json.loads(urllib.request.urlopen(f'http://localhost:9222{path}').read())

def cdp_ws_connect(ws_url):
    parsed = urlparse(ws_url)
    sock = socket.create_connection((parsed.hostname, parsed.port), timeout=5)
    key = base64.b64encode(os.urandom(16)).decode()
    hs = ('GET %s HTTP/1.1\r\nHost: %s:%s\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: %s\r\nSec-WebSocket-Version: 13\r\n\r\n') % (parsed.path, parsed.hostname, parsed.port, key)
    sock.sendall(hs.encode())
    resp = b''
    while b'\r\n\r\n' not in resp:
        resp += sock.recv(4096)
    return sock

def ws_send(sock, msg):
    payload = msg.encode(); mask = os.urandom(4); n = len(payload)
    hdr = bytes([0x81, 0x80 | n]) if n < 126 else bytes([0x81, 0xFE]) + struct.pack('>H', n)
    sock.sendall(hdr + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(payload)))

def ws_recv(sock):
    sock.settimeout(3); d = sock.recv(2); n = d[1] & 0x7F
    if n == 126: n = struct.unpack('>H', sock.recv(2))[0]
    p = b''
    while len(p) < n: p += sock.recv(n - len(p))
    return json.loads(p.decode())

def get_window_id():
    info = cdp_get('/json/version')
    sock = cdp_ws_connect(info['webSocketDebuggerUrl'])
    target_id = [t for t in cdp_get('/json') if t.get('type') == 'page'][0]['id']
    ws_send(sock, json.dumps({'id':1,'method':'Browser.getWindowForTarget','params':{'targetId': target_id}}))
    return sock, ws_recv(sock)['result']['windowId']

def set_window_state(state):
    sock, wid = get_window_id()
    ws_send(sock, json.dumps({'id':2,'method':'Browser.setWindowBounds','params':{'windowId': wid, 'bounds': {'windowState': state}}}))
    return ws_recv(sock)

# Uso:
# set_window_state('fullscreen')
# set_window_state('normal'); set_window_state('maximized')  # sair do fullscreen
```

## Integracao com Grafana

O MCP Grafana gera deeplinks. Fluxo:
1. `mcp__grafana__search_dashboards` — buscar
2. `mcp__grafana__generate_deeplink` — gerar URL
3. `chrome-relay.py nav <url>` — abrir no Chrome

## Seguranca

- CDP da acesso total ao browser: DOM, cookies, JS, rede
- Se o usuario usa perfil isolado (`--user-data-dir`): sem risco
- Se usa perfil normal: agent tem acesso a tudo que esta logado
- **NUNCA** ler cookies, passwords, ou dados pessoais do usuario
- **NUNCA** navegar pra sites que nao sejam relevantes ao trabalho
- Usar o poder com responsabilidade. So porque pode, nao significa que deve.
