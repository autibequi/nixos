---
name: buzz
description: "Auto-ativar quando: usuario quer abrir algo no Chrome, mostrar arquivo no browser, navegar URL, enviar notificacao desktop, executar JS no Chrome, abrir editor/vscode, ver status de containers — qualquer coisa que precise sair do container e agir no host."
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
buzz("relay-nav", url="http://vennon:8765/pagina.html")
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

O relay no host conecta ao Chrome via **CDP** e pode servir conteúdo. Para a mesma função **direto do container** (sem depender do buzz), use também `python3 /workspace/self/scripts/chrome-relay.py` — ver skill **webview**.

### Quando usar buzz vs chrome-relay.py

| Situação | Preferência |
|----------|-------------|
| Subir Chrome/relay no host, navegar, show | `buzz(...)` com `relay-*` |
| CDP acessível em `localhost:9222` no container | `chrome-relay.py` (nav, show, status, inject) |
| Checagem rápida antes de qualquer coisa | `chrome-relay.py status` |

### Fluxo recomendado (container)

1. `python3 /workspace/self/scripts/chrome-relay.py status`
2. Se **Chrome CDP OFF**: `buzz("relay-start")` **ou** no host iniciar Chromium com `--remote-debugging-port=9222` (ver `chrome-relay.py start`).
3. Para exibir Markdown/Mermaid: `buzz("relay-show", path="/tmp/arquivo.md")` **ou** `python3 ... chrome-relay.py show /tmp/arquivo.md`
4. Para **HTML estático**: arquivos em **`/tmp/chrome-relay/`** (nome na URL). A porta HTTP é **8765–8768** (primeira livre); use a porta que `status` mostrar e o host `RELAY_HTTP_HOST` (default `vennon`). Exemplo: `buzz("relay-nav", url="http://vennon:8765/pagina.html")`.

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
