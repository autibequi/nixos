---
name: buzz
description: "Auto-ativar quando: usuario quer abrir algo no Chrome, mostrar no relay, navegar URL, notificacao desktop, JS no Chrome, editor, logs de containers — IPC container→host. Relay visual: ver skill webview; agente chama relay-start por iniciativa."
---

# buzz — Container→Host IPC

`buzz` é o daemon que roda no **host** e expõe actions via socket Unix.
Do **container**, não existe o binário `buzz`: use **Python no socket** (abaixo).
No **host**, você pode usar `buzz call`, `buzz list`, `buzz status` no shell.

**Socket (container):** `~/.vennon/buzz.sock` — em muitos setups montado como `/home/claude/.vennon/buzz.sock`. Se `FileNotFoundError`, confira o path real do mount.

---

## Cliente Python (obrigatório no container)

```python
import json
import socket

BUZZ_SOCK = "/home/claude/.vennon/buzz.sock"  # ajuste se seu mount for outro


def buzz(action, **args):
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(BUZZ_SOCK)
    req = json.dumps({"id": "1", "action": action, "args": args, "source": "claude"}) + "\n"
    sock.sendall(req.encode())
    resp = json.loads(sock.recv(65536).decode())
    sock.close()
    return resp
```

Uso relay (exemplos):

```python
buzz("relay-status")
buzz("relay-start")
buzz("relay-nav", url="http://127.0.0.1:8765/pagina.html")  # URL = Public base do `chrome-relay.py status` + arquivo
buzz("relay-show", path="/tmp/minha-viz.md")
buzz("relay-inject", js="document.title")
buzz("relay-tabs")
buzz("relay-stop")
```

One-liner bash equivalente ao `relay-start`:

```bash
python3 -c "
import json, socket
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect('/home/claude/.vennon/buzz.sock')
s.sendall((json.dumps({'id':'1','action':'relay-start','args':{},'source':'claude'})+'\n').encode())
print(s.recv(4096).decode())
s.close()
"
```

---

## Relay (Chrome + HTTP no host)

O relay no host conecta ao Chrome via **CDP** e pode servir conteúdo. Para **mostrar no relay** a partir do container (incluindo `chrome-relay.py`), ver skill **webview**.

### Iniciativa do agente

Se a tarefa for mostrar algo no browser e o CDP não estiver ativo, **chame `buzz("relay-start")` você mesmo** — não peça ao usuário para “abrir o Chrome” ou “ligar o relay”. Detalhes e ordem (status → start → nav/show): skill **webview**.

### Quando usar buzz vs chrome-relay.py

| Situação | Preferência |
|----------|-------------|
| Subir Chrome/relay no host, navegar, show | `buzz(...)` com `relay-*` |
| CDP acessível em `localhost:9222` no container | `chrome-relay.py` (nav, show, status, inject) |
| Checagem rápida antes de qualquer coisa | `chrome-relay.py status` |

### Fluxo recomendado (container)

1. `python3 /workspace/self/scripts/chrome-relay.py status`
2. Se **Chrome CDP OFF**: **`buzz("relay-start")` imediatamente** (iniciativa), depois `status` de novo; só se falhar, orientar o host com `chrome-relay.py start`.
3. Para exibir Markdown/Mermaid: `buzz("relay-show", path="/tmp/arquivo.md")` **ou** `python3 ... chrome-relay.py show /tmp/arquivo.md`
4. Para **HTML estático**: arquivos em **`/tmp/chrome-relay/`** (nome na URL). Porta **8765–8768**; monte a URL a partir de **`Public base:`** em `chrome-relay.py status`. Exemplo: `buzz("relay-nav", url="http://127.0.0.1:8765/pagina.html")` se for o que o browser alcança.
5. **Mermaid holodeck em modo live** (SSE, outro servidor HTTP — ex. `127.0.0.1:9876`): abrir `buzz("relay-nav", url="http://127.0.0.1:9876/base.html")` quando o utilizador quiser **cooperar** no diagrama. Para **ler o estado atual** do desenho na aba (antes de editar): `relay-inject` no textarea `#hk-mermaid-ta` ou nós no SVG — pipeline completo na skill **webview**, secção **Mermaid Live**.

---

## Outras actions (via `buzz(...)` no container)

| Action | Exemplo |
|--------|---------|
| Notificação desktop | `buzz("notify", message="Build concluído")` |
| Abrir no Zed | `buzz("open-editor", path="/home/pedrinho/projects/meu-app")` |
| Abrir no VS Code | `buzz("open-vscode", path="/home/pedrinho/projects/meu-app")` |
| Chrome sem CDP | `buzz("open-chrome", url="https://exemplo.com")` |
| Status podman | `buzz("podman-status")` |
| Logs serviço | `buzz("podman-logs", service="monolito", tail=50)` |

**Somente no host (shell):**

```bash
buzz call notify --message="Build concluído"
```

---

## Paths — container → host

O daemon roda no **host**. Paths `~/` no buzz resolvem para o home do host.

| No container | No host (para buzz) |
|----------------|---------------------|
| `/workspace/projects/` | `~/projects/` (ex.: `/home/pedrinho/projects/`) |
| `/workspace/host/` | `~/nixos/` |
| `/workspace/self/` | caminho nixos/vennon/self no host |
| `/tmp/arquivo.md` | `/tmp/arquivo.md` (igual) |

**Relay show:** paths aceitos pelo daemon incluem `/tmp` e projetos; conteúdo servido para HTML estático deve estar em **`/tmp/chrome-relay/`** para o servidor HTTP do relay local.

---

## Validações (daemon)

| Action | Restrição |
|--------|-----------|
| `open-editor`, `open-vscode` | path em `~/projects` ou `~/nixos` |
| `open-chrome` | URL `https://` |
| `relay-nav` | URL começa com `http` |
| `relay-show` | path em `~/projects`, `~/nixos` ou `/tmp` |
| `relay-inject` | JS máx. 5000 chars |
| `notify` | mensagem máx. 500 chars |
| `podman-logs` | service um dos conhecidos (monolito, bo-container, front-student, reverseproxy) |

Se negado: resposta com `status: denied` e motivo.

---

## Daemon não está rodando

No host: `systemctl --user start buzz` ou `systemctl --user enable --now buzz`.

Config: `~/.config/vennon/buzz.yaml` (relida por request).
