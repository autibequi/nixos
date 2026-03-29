#!/usr/bin/env python3
"""
Chrome Relay — Controle total do Chrome via CDP + servidor de conteudo local.

Unifica: navegacao (URLs externas), servir conteudo (Markdown/Mermaid/HTML),
e controle programatico do browser via Chrome DevTools Protocol.

Requer Chrome/Chromium com --remote-debugging-port=9222 no host.
Container usa network_mode: host, entao localhost:9222 funciona direto.
URLs publicas usam RELAY_HTTP_HOST (default vennon); export para outro hostname se o Chrome nao resolver.
Flags padrao do Chrome: RELAY_CHROME_FLAGS (sem traducao automatica nem bubble restaurar paginas).

Comandos:
  chrome-relay.py nav <url> [title]     — Navega o Chrome para uma URL
  chrome-relay.py serve [--once]        — Sobe servidor HTTP (Mermaid/Markdown)
  chrome-relay.py show <file.md>        — Serve arquivo e navega Chrome pra ele
  chrome-relay.py inject <js>           — Executa JS na aba ativa
  chrome-relay.py tabs                  — Lista abas abertas
  chrome-relay.py status                — Status do Chrome + servidor
  chrome-relay.py start                 — Instrucoes para iniciar Chrome no host
"""
import base64
import http.client
import json
import os
import re
import socket
import struct
import sys
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
from socketserver import ThreadingMixIn
from urllib.parse import urlparse, quote

CDP_HOST = "localhost"
CDP_PORT = 9222
SERVE_HOST = "127.0.0.1"
SERVE_PORTS = [8765, 8766, 8767, 8768]
CONTENT_DIR = os.environ.get("RELAY_CONTENT_DIR", "/tmp/chrome-relay")
CONTENT_FILE = os.path.join(CONTENT_DIR, "content.md")
PID_FILE = os.path.join(CONTENT_DIR, ".server.pid")
# Hostname usado nas URLs que o Chrome abre (deve resolver no browser do usuario).
# Skills/documentacao usam "vennon"; override com RELAY_HTTP_HOST se necessario (ex.: 127.0.0.1).
RELAY_HTTP_HOST = os.environ.get("RELAY_HTTP_HOST", "vennon")

# Chrome/Chromium: sem oferta de tradução automática nem bubble "restaurar páginas" após encerramento.
# Sobrescreva com RELAY_CHROME_FLAGS="..." se precisar (valor substitui o default inteiro).
_RELAY_CHROME_FLAGS_DEFAULT = (
    "--disable-features=Translate "
    "--disable-session-crashed-bubble"
)
RELAY_CHROME_FLAGS = os.environ.get("RELAY_CHROME_FLAGS", _RELAY_CHROME_FLAGS_DEFAULT)


def relay_public_base(port):
    """Base URL http://<host>:<port> para navegacao no Chrome."""
    return "http://%s:%d" % (RELAY_HTTP_HOST, port)


# ===========================================================================
# CDP — Chrome DevTools Protocol
# ===========================================================================

def cdp_get(path):
    try:
        conn = http.client.HTTPConnection(CDP_HOST, CDP_PORT, timeout=3)
        conn.request("GET", path)
        data = conn.getresponse().read().decode()
        conn.close()
        return json.loads(data) if data else None
    except (ConnectionRefusedError, OSError, json.JSONDecodeError):
        return None


def cdp_ok():
    try:
        with socket.create_connection((CDP_HOST, CDP_PORT), timeout=1):
            return True
    except (ConnectionRefusedError, OSError):
        return False


def cdp_tabs():
    return cdp_get("/json") or []


def cdp_find_page_tab():
    for tab in cdp_tabs():
        if tab.get("type") == "page" and tab.get("webSocketDebuggerUrl"):
            return tab
    return None


def cdp_ws_connect(ws_url):
    parsed = urlparse(ws_url)
    sock = socket.create_connection((parsed.hostname, parsed.port), timeout=5)
    key = base64.b64encode(os.urandom(16)).decode()
    handshake = (
        "GET %s HTTP/1.1\r\n"
        "Host: %s:%s\r\n"
        "Upgrade: websocket\r\n"
        "Connection: Upgrade\r\n"
        "Sec-WebSocket-Key: %s\r\n"
        "Sec-WebSocket-Version: 13\r\n\r\n"
    ) % (parsed.path, parsed.hostname, parsed.port, key)
    sock.sendall(handshake.encode())
    resp = b""
    while b"\r\n\r\n" not in resp:
        chunk = sock.recv(4096)
        if not chunk:
            raise ConnectionError("WS handshake failed")
        resp += chunk
    if b"101" not in resp.split(b"\r\n")[0]:
        sock.close()
        raise ConnectionError("WS upgrade rejected")
    return sock


def ws_send(sock, msg):
    payload = msg.encode()
    mask = os.urandom(4)
    length = len(payload)
    if length < 126:
        header = bytes([0x81, 0x80 | length])
    elif length < 65536:
        header = bytes([0x81, 0x80 | 126]) + struct.pack(">H", length)
    else:
        header = bytes([0x81, 0x80 | 127]) + struct.pack(">Q", length)
    header += mask
    masked = bytes(b ^ mask[i % 4] for i, b in enumerate(payload))
    sock.sendall(header + masked)


def ws_recv(sock, timeout=3):
    sock.settimeout(timeout)
    try:
        data = sock.recv(2)
        if len(data) < 2:
            return None
        length = data[1] & 0x7F
        masked = bool(data[1] & 0x80)
        if length == 126:
            length = struct.unpack(">H", sock.recv(2))[0]
        elif length == 127:
            length = struct.unpack(">Q", sock.recv(8))[0]
        if masked:
            mask = sock.recv(4)
        payload = b""
        while len(payload) < length:
            chunk = sock.recv(length - len(payload))
            if not chunk:
                break
            payload += chunk
        if masked:
            payload = bytes(b ^ mask[i % 4] for i, b in enumerate(payload))
        return payload.decode()
    except socket.timeout:
        return None


def cdp_send(method, params=None, tab=None):
    """Send a CDP command and return result."""
    if tab is None:
        tab = cdp_find_page_tab()
    if not tab:
        return None, "No page tab found"
    try:
        sock = cdp_ws_connect(tab["webSocketDebuggerUrl"])
    except (ConnectionError, OSError) as e:
        return None, str(e)
    msg = {"id": 1, "method": method}
    if params:
        msg["params"] = params
    ws_send(sock, json.dumps(msg))
    resp = ws_recv(sock)
    sock.close()
    if resp:
        data = json.loads(resp)
        if "error" in data:
            return None, data["error"].get("message", "CDP error")
        return data.get("result"), None
    return None, "No response"


def cdp_navigate(url, tab=None):
    result, err = cdp_send("Page.navigate", {"url": url}, tab)
    if err:
        return False, err
    # Activate the tab
    if tab:
        cdp_get("/json/activate/" + tab["id"])
    return True, "OK"


def cdp_eval(expression, tab=None):
    result, err = cdp_send("Runtime.evaluate", {
        "expression": expression,
        "returnByValue": True,
    }, tab)
    if err:
        return None, err
    if result and "result" in result:
        return result["result"].get("value"), None
    return result, None


# ===========================================================================
# Content Server — Serve Markdown/Mermaid/HTML locally
# ===========================================================================

MERMAID_INIT = """\
mermaid.initialize({
  startOnLoad: false,
  theme: 'dark',
  themeVariables: {
    primaryColor: '#7c3aed',
    primaryTextColor: '#e4e4e7',
    primaryBorderColor: '#2a2a30',
    lineColor: '#71717a',
    secondaryColor: '#18181c',
    tertiaryColor: '#0f0f12'
  }
});"""

HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Leech Relay</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:ital,opsz,wght@0,9..40,400;0,9..40,600;1,9..40,400&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
  <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
  <style>
    :root {
      --bg: #0f0f12; --surface: #18181c; --border: #2a2a30;
      --text: #e4e4e7; --text-muted: #71717a;
      --accent: #a78bfa; --accent-dim: #7c3aed;
      --live: #22c55e;
    }
    * { box-sizing: border-box; }
    html, body {
      width: 100%; height: 100%; margin: 0; overflow: hidden;
      font-family: 'DM Sans', system-ui, sans-serif;
      background: var(--bg); color: var(--text); line-height: 1.6;
    }
    .dot {
      position: fixed; top: 10px; right: 12px; z-index: 99;
      width: 7px; height: 7px; border-radius: 50%;
      background: var(--text-muted); display: inline-block;
    }
    .dot.live { background: var(--live); box-shadow: 0 0 6px var(--live); }
    #content {
      width: 100vw; height: 100vh;
      display: flex; flex-direction: column;
      overflow-y: auto;
      padding: 2rem 3rem;
    }
    /* Markdown styles */
    #content h1 { font-size: 1.75rem; font-weight: 600; margin: 0 0 0.75rem; }
    #content h2 { font-size: 1.25rem; font-weight: 600; margin: 1.5rem 0 0.5rem; border-bottom: 1px solid var(--border); padding-bottom: 0.35rem; }
    #content h3 { font-size: 1.1rem; font-weight: 600; margin: 1.25rem 0 0.4rem; }
    #content p { margin: 0 0 0.75rem; color: var(--text-muted); }
    #content ul, #content ol { margin: 0 0 0.75rem; padding-left: 1.5rem; color: var(--text-muted); }
    #content li { margin: 0.25rem 0; }
    #content pre {
      font-family: 'JetBrains Mono', monospace; font-size: 0.875rem;
      background: var(--surface); border-radius: 8px;
      padding: 1rem 1.25rem; overflow-x: auto; margin: 0.75rem 0;
    }
    #content code {
      font-family: 'JetBrains Mono', monospace; font-size: 0.875em;
      color: var(--accent); padding: 0.2em 0.45em; border-radius: 4px;
    }
    #content pre code { color: var(--text); padding: 0; }
    #content blockquote {
      margin: 0.75rem 0; padding-left: 1rem;
      border-left: 3px solid var(--accent-dim); color: var(--text-muted);
    }
    #content a { color: var(--accent); text-decoration: none; }
    #content a:hover { text-decoration: underline; }
    #content hr { border: none; border-top: 1px solid var(--border); margin: 1.5rem 0; }
    #content table { border-collapse: collapse; width: 100%; margin: 0.75rem 0; }
    #content th, #content td { border: 1px solid var(--border); padding: 0.5rem 0.75rem; text-align: left; }
    #content th { background: var(--surface); font-weight: 600; }
    .mermaid {
      position: relative; overflow: hidden; cursor: grab;
      flex: 1; min-height: 0;
      user-select: none; -webkit-user-select: none; touch-action: none;
    }
    /* fullscreen: single mermaid fills entire viewport */
    #content:has(> .mermaid:only-child),
    #content:has(> div > .mermaid:only-child) {
      padding: 0;
    }
    .mermaid:only-child {
      width: 100vw; height: 100vh;
    }
    .mermaid.panning { cursor: grabbing; }
    .mermaid svg { display: block; transform-origin: 0 0; will-change: transform; }
    .z-hint {
      position: absolute; bottom: 12px; right: 16px; pointer-events: none;
      font: 500 0.6rem/1 'JetBrains Mono', monospace; color: var(--text-muted);
      opacity: 0; transition: opacity 0.2s;
    }
    .mermaid:hover .z-hint { opacity: 1; }
    .z-reset {
      position: absolute; top: 12px; right: 16px; z-index: 5;
      font: 500 0.65rem 'JetBrains Mono', monospace; color: var(--text-muted);
      background: rgba(15,15,18,0.7); border: 1px solid var(--border);
      padding: 3px 10px; border-radius: 4px; cursor: pointer;
      opacity: 0; transition: opacity 0.2s; backdrop-filter: blur(4px);
    }
    .mermaid:hover .z-reset { opacity: 1; }
  </style>
</head>
<body>
  <div class="dot" id="dot"></div>
  <div id="content">Aguardando...</div>
  <script>
    MERMAID_INIT

    function extractParts(raw) {
      const parts = [];
      const re = /```mermaid\\s*([\\s\\S]*?)```/g;
      let idx = 0, m;
      while ((m = re.exec(raw)) !== null) {
        if (m.index > idx) parts.push({ type: 'md', text: raw.slice(idx, m.index) });
        parts.push({ type: 'mermaid', text: m[1].trim() });
        idx = m.index + m[0].length;
      }
      if (idx < raw.length) parts.push({ type: 'md', text: raw.slice(idx) });
      return parts;
    }

    async function render(raw) {
      const el = document.getElementById('content');
      const parts = extractParts(raw);
      let html = '';
      for (const p of parts) {
        if (p.type === 'md') {
          html += p.text ? '<div>' + marked.parse(p.text) + '</div>' : '';
        } else {
          html += '<div class="mermaid">' + p.text + '</div>';
        }
      }
      el.innerHTML = html || '<em style="color:var(--text-muted)">Aguardando...</em>';
      if (typeof mermaid !== 'undefined') {
        try { await mermaid.run({ nodes: el.querySelectorAll('.mermaid'), suppressErrors: true }); }
        catch (e) { console.warn('mermaid', e); }
        setTimeout(function() {
          el.querySelectorAll('.mermaid').forEach(makeZoomable);
        }, 80);
      }
      /* auto fullscreen when there is only a mermaid diagram */
      if (!document.fullscreenElement) {
        var merms = el.querySelectorAll('.mermaid');
        var nonEmpty = Array.from(el.children).filter(function(c){ return c.textContent.trim() && !c.classList.contains('mermaid'); });
        if (merms.length === 1 && nonEmpty.length === 0) {
          document.documentElement.requestFullscreen().catch(function(){});
        }
      }
    }

    function makeZoomable(box) {
      if (box.dataset.z) return;
      var svg = box.querySelector('svg');
      if (!svg) return;
      box.dataset.z = '1';

      /* fix SVG sizing so it doesn't collapse */
      var nat = svg.getBoundingClientRect();
      if (nat.height < 20) { setTimeout(function(){ box.dataset.z=''; makeZoomable(box); }, 150); return; }
      svg.style.margin = '0';
      /* fit diagram in viewport with padding */
      var bw = box.offsetWidth || window.innerWidth;
      var bh = box.offsetHeight || window.innerHeight;
      var pad = 40;
      var scaleX = (bw - pad * 2) / nat.width;
      var scaleY = (bh - pad * 2) / nat.height;
      s = Math.min(scaleX, scaleY, 1);
      tx = (bw - nat.width * s) / 2;
      ty = (bh - nat.height * s) / 2;
      initS = s; initTx = tx; initTy = ty;
      put();

      /* hint + reset */
      var hint = document.createElement('div');
      hint.className = 'z-hint'; hint.textContent = 'scroll = zoom  \xb7  drag = pan';
      var btn = document.createElement('button');
      btn.className = 'z-reset'; btn.textContent = '\u27f3 reset';
      box.appendChild(hint); box.appendChild(btn);

      var s=1, tx=0, ty=0, initS, initTx, initTy;
      function put() { svg.style.transform = 'translate('+tx+'px,'+ty+'px) scale('+s+')'; }

      btn.addEventListener('click', function(e) { e.stopPropagation(); s=initS; tx=initTx; ty=initTy; put(); });

      /* zoom on wheel */
      box.addEventListener('wheel', function(e) {
        e.preventDefault(); e.stopPropagation();
        var r = box.getBoundingClientRect();
        var mx = e.clientX - r.left, my = e.clientY - r.top;
        var f = e.deltaY < 0 ? 1.12 : 0.89;
        var ns = Math.min(Math.max(s * f, 0.08), 15);
        tx = mx - (mx - tx) * (ns / s);
        ty = my - (my - ty) * (ns / s);
        s = ns; put();
      }, { passive: false });

      /* drag with pointer capture */
      var px, py, ptx, pty;
      box.addEventListener('pointerdown', function(e) {
        if (e.button && e.button !== 0) return;
        box.setPointerCapture(e.pointerId);
        px = e.clientX; py = e.clientY; ptx = tx; pty = ty;
        box.classList.add('panning'); e.preventDefault();
      });
      box.addEventListener('pointermove', function(e) {
        if (!box.hasPointerCapture(e.pointerId)) return;
        tx = ptx + (e.clientX - px); ty = pty + (e.clientY - py); put();
      });
      box.addEventListener('pointerup', function(e) {
        box.releasePointerCapture(e.pointerId);
        box.classList.remove('panning');
      });
      box.addEventListener('pointercancel', function(e) {
        box.releasePointerCapture(e.pointerId);
        box.classList.remove('panning');
      });

      /* pinch zoom (touch) */
      var ptrs = {};
      box.addEventListener('pointerdown', function(e) { ptrs[e.pointerId] = {x:e.clientX,y:e.clientY}; });
      box.addEventListener('pointermove', function(e) {
        ptrs[e.pointerId] = {x:e.clientX,y:e.clientY};
        var ids = Object.keys(ptrs);
        if (ids.length === 2) {
          var a = ptrs[ids[0]], b = ptrs[ids[1]];
          var nd = Math.hypot(a.x-b.x, a.y-b.y);
          if (box._pd) { s = Math.min(Math.max(s * nd/box._pd, 0.08), 15); put(); }
          box._pd = nd;
        }
      });
      box.addEventListener('pointerup', function(e) { delete ptrs[e.pointerId]; if(!Object.keys(ptrs).length) box._pd=0; });
    }

    // SSE — live reload
    const dot = document.getElementById('dot');
    function connect() {
      dot.className = 'dot';
      const es = new EventSource('/stream');
      es.onopen = () => { dot.className = 'dot live'; };
      es.onmessage = ev => render(ev.data);
      es.onerror = () => { dot.className = 'dot'; es.close(); setTimeout(connect, 1500); };
    }
    connect();
  </script>
</body>
</html>""".replace("    MERMAID_INIT", MERMAID_INIT)


def read_content():
    try:
        with open(CONTENT_FILE, "r", encoding="utf-8") as f:
            return f.read()
    except (FileNotFoundError, OSError):
        return ""


class ContentHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path in ("/", "/index.html"):
            self._bytes(HTML_TEMPLATE.encode(), "text/html; charset=utf-8")
        elif self.path == "/stream":
            self._sse()
        elif self.path == "/content":
            self._bytes(read_content().encode(), "text/plain; charset=utf-8")
        elif self.path == "/health":
            self._bytes(b'{"ok":true}', "application/json")
        else:
            fname = os.path.basename(self.path.split("?")[0])
            fpath = os.path.join(CONTENT_DIR, fname)
            if fname and os.path.isfile(fpath):
                ext = os.path.splitext(fname)[1].lstrip(".").lower()
                ct = {"html": "text/html", "js": "text/javascript",
                      "css": "text/css", "json": "application/json"}.get(ext, "application/octet-stream")
                with open(fpath, "rb") as f:
                    self._bytes(f.read(), ct + "; charset=utf-8")
            else:
                self.send_response(404)
                self.end_headers()

    def _bytes(self, data, ct, status=200):
        self.send_response(status)
        self.send_header("Content-Type", ct)
        self.send_header("Content-Length", len(data))
        self.end_headers()
        self.wfile.write(data)

    def _sse(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("X-Accel-Buffering", "no")
        self.end_headers()
        last_mtime = 0
        try:
            while True:
                try:
                    mtime = os.stat(CONTENT_FILE).st_mtime
                except OSError:
                    mtime = 0
                if mtime != last_mtime:
                    last_mtime = mtime
                    body = read_content()
                    for line in body.split("\n"):
                        self.wfile.write(("data: " + line + "\n").encode())
                    self.wfile.write(b"\n")
                    self.wfile.flush()
                time.sleep(0.3)
        except (BrokenPipeError, ConnectionResetError, OSError):
            pass

    def log_message(self, fmt, *args):
        pass  # silent


class ThreadedServer(ThreadingMixIn, HTTPServer):
    allow_reuse_address = True
    daemon_threads = True


def relay_health_ok(port):
    """True apenas se for o ContentHandler deste script (GET /health -> {\"ok\":true})."""
    try:
        conn = http.client.HTTPConnection("127.0.0.1", port, timeout=0.5)
        conn.request("GET", "/health")
        resp = conn.getresponse()
        body = resp.read().decode().strip()
        conn.close()
        return resp.status == 200 and body == '{"ok":true}'
    except (OSError, TimeoutError):
        return False


def find_serve_port():
    """Porta do servidor deste relay. Ignora processos estranhos (ex.: `http.server` na mesma porta)."""
    for port in SERVE_PORTS:
        try:
            with socket.create_connection(("127.0.0.1", port), timeout=0.3):
                pass
        except (ConnectionRefusedError, OSError):
            continue
        if relay_health_ok(port):
            return port
    return None


def start_server():
    """Start content server, return port or None."""
    existing = find_serve_port()
    if existing:
        return existing

    os.makedirs(CONTENT_DIR, exist_ok=True)
    for port in SERVE_PORTS:
        try:
            server = ThreadedServer((SERVE_HOST, port), ContentHandler)
            try:
                with open(PID_FILE, "w") as f:
                    f.write(str(os.getpid()))
            except OSError:
                pass
            import threading
            t = threading.Thread(target=server.serve_forever, daemon=True)
            t.start()
            return port
        except OSError:
            continue
    return None


# ===========================================================================
# CLI commands
# ===========================================================================

def cmd_nav(args):
    url = args[0] if args else ""
    if not url:
        print("Usage: chrome-relay.py nav <url> [title]", file=sys.stderr)
        sys.exit(1)
    if not cdp_ok():
        print("FAIL: Chrome CDP not reachable (localhost:%d)" % CDP_PORT, file=sys.stderr)
        print(
            "Start Chrome with: chromium --remote-debugging-port=%d %s"
            % (CDP_PORT, RELAY_CHROME_FLAGS),
            file=sys.stderr,
        )
        sys.exit(1)
    ok, msg = cdp_navigate(url)
    print("OK" if ok else "FAIL: %s" % msg)
    sys.exit(0 if ok else 1)


def cmd_show(args):
    """Serve a markdown file and navigate Chrome to it."""
    filepath = args[0] if args else ""
    if not filepath:
        print("Usage: chrome-relay.py show <file.md>", file=sys.stderr)
        sys.exit(1)
    try:
        with open(filepath, "r") as f:
            content = f.read()
    except FileNotFoundError:
        # Treat argument as inline content
        content = filepath

    os.makedirs(CONTENT_DIR, exist_ok=True)
    with open(CONTENT_FILE, "w") as f:
        f.write(content)

    port = start_server()
    if not port:
        print("FAIL: Could not start content server", file=sys.stderr)
        sys.exit(1)

    url = relay_public_base(port) + "/"
    if cdp_ok():
        ok, msg = cdp_navigate(url)
        print("OK: Serving on %s, Chrome navigated" % url if ok else "Serving on %s but Chrome nav failed: %s" % (url, msg))
    else:
        print("OK: Serving on %s (Chrome CDP not available — open manually)" % url)


def cmd_inject(args):
    js = " ".join(args) if args else ""
    if not js:
        print("Usage: chrome-relay.py inject <javascript>", file=sys.stderr)
        sys.exit(1)
    if not cdp_ok():
        print("FAIL: Chrome CDP not reachable", file=sys.stderr)
        print("Start Chrome with: chromium --remote-debugging-port=%d %s" % (CDP_PORT, RELAY_CHROME_FLAGS), file=sys.stderr)
        sys.exit(1)
    result, err = cdp_eval(js)
    if err:
        print("FAIL: %s" % err, file=sys.stderr)
        sys.exit(1)
    print(json.dumps(result) if result is not None else "OK (void)")


def cmd_tabs(args=None):
    if not cdp_ok():
        print("Chrome CDP not reachable", file=sys.stderr)
        print("Start Chrome with: chromium --remote-debugging-port=%d %s" % (CDP_PORT, RELAY_CHROME_FLAGS), file=sys.stderr)
        sys.exit(1)
    tabs = cdp_tabs()
    for t in tabs:
        if t.get("type") == "page":
            print("  %s  %-40s  %s" % (t["id"][:8], t.get("title", "?")[:40], t.get("url", "?")[:60]))
    print("\n%d tab(s)" % len([t for t in tabs if t.get("type") == "page"]))


def cmd_status(args=None):
    chrome = cdp_ok()
    serve = find_serve_port()
    print("Chrome CDP:     %s" % ("OK (:%d)" % CDP_PORT if chrome else "OFF"))
    print("Content server: %s" % ("OK (:%d)" % serve if serve else "OFF"))
    print("RELAY_HTTP_HOST: %s" % RELAY_HTTP_HOST)
    if serve:
        print("Public base:    %s/" % relay_public_base(serve))
    if chrome:
        tabs = cdp_tabs()
        pages = [t for t in tabs if t.get("type") == "page"]
        print("Tabs:           %d" % len(pages))
        for t in pages:
            print("  %s  %s" % (t.get("title", "?")[:40], t.get("url", "?")[:50]))


def cmd_serve(args):
    once = "--once" in args
    existing = find_serve_port()
    if once and existing:
        print("Content server already on port %d" % existing, file=sys.stderr)
        sys.exit(0)

    os.makedirs(CONTENT_DIR, exist_ok=True)
    server = None
    port_used = None
    for port in SERVE_PORTS:
        try:
            server = ThreadedServer((SERVE_HOST, port), ContentHandler)
            port_used = port
            break
        except OSError:
            continue
    if not server:
        print("Could not bind to any port", file=sys.stderr)
        sys.exit(1)

    try:
        with open(PID_FILE, "w") as f:
            f.write(str(os.getpid()))
    except OSError:
        pass

    chrome = "OK" if cdp_ok() else "OFF"
    print(
        "Content server: %s (Chrome: %s)" % (relay_public_base(port_used), chrome),
        file=sys.stderr,
    )
    sys.stderr.flush()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    server.server_close()


def cmd_start(args=None):
    flags = RELAY_CHROME_FLAGS.strip()
    print("Para iniciar o Chrome relay no host:")
    print("")
    print("  chromium --remote-debugging-port=9222 --user-data-dir=/tmp/leech-relay %s &" % flags)
    print("")
    print("Ou com seu perfil normal (agent tera acesso total ao browser):")
    print("")
    print("  chromium --remote-debugging-port=9222 %s &" % flags)
    print("")
    print("Flags padrao (traducao automatica + bubble restaurar paginas): em RELAY_CHROME_FLAGS ou veja o inicio do script.")
    print("Depois, o agent controla via CDP automaticamente.")


def main():
    cmds = {
        "nav": cmd_nav, "navigate": cmd_nav,
        "show": cmd_show,
        "inject": cmd_inject,
        "tabs": cmd_tabs,
        "status": cmd_status,
        "serve": cmd_serve,
        "start": cmd_start,
    }
    if len(sys.argv) < 2 or sys.argv[1] not in cmds:
        print("Usage: chrome-relay.py <command> [args]")
        print("  nav <url> [title]     Navigate Chrome to URL")
        print("  show <file.md>        Serve markdown + navigate Chrome")
        print("  inject <js>           Execute JS in active tab")
        print("  tabs                  List open tabs")
        print("  serve [--once]        Start content server")
        print("  status                Check everything")
        print("  start                 Show how to start Chrome")
        sys.exit(1)

    cmds[sys.argv[1]](sys.argv[2:])


if __name__ == "__main__":
    main()
