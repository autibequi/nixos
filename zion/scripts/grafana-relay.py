#!/usr/bin/env python3
"""
Grafana Relay — Recebe URLs via POST /navigate e envia para Chrome via SSE.

Chrome fica com uma aba aberta em http://zion:<port> (landing page).
Quando o agent faz POST /navigate {"url":"..."}, a página redireciona instantaneamente.

Uso:
  python3 grafana-relay.py          # sobe servidor
  python3 grafana-relay.py --once   # idempotente — sobe só se não houver servidor

Enviar URL:
  curl -s -X POST http://localhost:8780/navigate \
    -H 'Content-Type: application/json' \
    -d '{"url":"https://grafana.example.com/d/abc","title":"My Dashboard"}'
"""
from http.server import HTTPServer, BaseHTTPRequestHandler
from socketserver import ThreadingMixIn
import json
import os
import socket
import sys
import threading
import time

PORT_FALLBACKS = [8780, 8781, 8782, 8783]
HOST = "127.0.0.1"

# Shared state — last navigation event
_lock = threading.Lock()
_state = {"url": "", "title": "", "ts": 0}
_event = threading.Event()


def pid_path():
    ws = os.environ.get("WORKSPACE", "/workspace")
    return os.path.join(ws, ".grafana-relay.pid")


def is_server_running():
    for port in PORT_FALLBACKS:
        try:
            with socket.create_connection(("127.0.0.1", port), timeout=0.5):
                return port
        except (ConnectionRefusedError, OSError):
            pass
    return None


# ---------------------------------------------------------------------------
# HTML
# ---------------------------------------------------------------------------

HTML_PAGE = r"""<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Grafana Relay</title>
  <style>
    :root {
      --bg: #0f0f12; --surface: #18181c; --border: #2a2a30;
      --text: #e4e4e7; --text-muted: #71717a;
      --accent: #f97316; --accent-dim: #ea580c;
      --live: #22c55e; --reconnect: #f59e0b;
    }
    * { box-sizing: border-box; }
    body {
      font-family: 'DM Sans', system-ui, sans-serif;
      background: var(--bg); color: var(--text);
      margin: 0; min-height: 100vh;
      display: flex; align-items: center; justify-content: center;
    }
    .container {
      text-align: center; max-width: 32rem; padding: 2rem;
    }
    .logo {
      font-size: 2.5rem; margin-bottom: 0.5rem;
      filter: grayscale(0.3);
    }
    .brand {
      font-size: 0.8125rem; font-weight: 600; letter-spacing: 0.08em;
      text-transform: uppercase; color: var(--text-muted); margin-bottom: 1.5rem;
    }
    .brand span { color: var(--accent); }
    .status {
      display: inline-flex; align-items: center; gap: 0.5rem;
      font-size: 0.875rem; font-weight: 600; color: var(--text-muted);
      padding: 0.5rem 1rem; border-radius: 8px;
      background: var(--surface); border: 1px solid var(--border);
      margin-bottom: 1.5rem;
    }
    .dot {
      width: 8px; height: 8px; border-radius: 50%;
      background: var(--text-muted);
    }
    .dot.live { background: var(--live); box-shadow: 0 0 8px var(--live); }
    .dot.reconnecting { background: var(--reconnect); }
    .hint {
      font-size: 0.8125rem; color: var(--text-muted); line-height: 1.6;
    }
    .hint code {
      font-family: 'JetBrains Mono', monospace; font-size: 0.8em;
      background: var(--surface); color: var(--accent); padding: 0.2em 0.5em;
      border-radius: 4px;
    }
    #last-nav {
      margin-top: 1.5rem; font-size: 0.8125rem; color: var(--text-muted);
      min-height: 1.5em;
    }
    #last-nav a { color: var(--accent); text-decoration: none; }
    #last-nav a:hover { text-decoration: underline; }
    .nav-flash {
      position: fixed; top: 0; left: 0; right: 0;
      height: 3px; background: var(--accent);
      transform: scaleX(0); transform-origin: left;
      transition: transform 0.3s ease-out;
    }
    .nav-flash.active { transform: scaleX(1); }
  </style>
</head>
<body>
  <div class="nav-flash" id="flash"></div>
  <div class="container">
    <div class="logo">🎯</div>
    <div class="brand"><span>Grafana</span> Relay</div>
    <div class="status">
      <div class="dot" id="dot"></div>
      <span id="status-text">conectando...</span>
    </div>
    <div class="hint">
      Aguardando comandos do agent.<br>
      Use <code>/grafana:dashboard</code> para navegar.
    </div>
    <div id="last-nav"></div>
  </div>
  <script>
    const dot = document.getElementById('dot');
    const statusText = document.getElementById('status-text');
    const lastNav = document.getElementById('last-nav');
    const flash = document.getElementById('flash');
    let lastTs = 0;

    function connect() {
      statusText.textContent = 'conectando...';
      dot.className = 'dot';
      const es = new EventSource('/events');
      es.onopen = () => {
        statusText.textContent = 'aguardando';
        dot.className = 'dot live';
      };
      es.addEventListener('navigate', (ev) => {
        const data = JSON.parse(ev.data);
        if (data.url && data.ts > lastTs) {
          lastTs = data.ts;
          // Flash bar
          flash.classList.remove('active');
          void flash.offsetWidth;
          flash.classList.add('active');
          setTimeout(() => flash.classList.remove('active'), 600);
          // Show what we're navigating to
          const title = data.title || data.url;
          lastNav.innerHTML = 'Aberto: <a href="' + data.url + '" target="_blank">' + title + '</a>';
          // Open in new tab (keeps relay alive) or reuse existing grafana tab
          if (window._grafanaTab && !window._grafanaTab.closed) {
            window._grafanaTab.location.href = data.url;
            window._grafanaTab.focus();
          } else {
            window._grafanaTab = window.open(data.url, 'grafana-dash');
          }
        }
      });
      es.onerror = () => {
        statusText.textContent = 'reconectando...';
        dot.className = 'dot reconnecting';
        es.close();
        setTimeout(connect, 2000);
      };
    }
    connect();
  </script>
</body>
</html>"""


# ---------------------------------------------------------------------------
# Handler
# ---------------------------------------------------------------------------

class RelayHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path in ("/", "/index.html"):
            self._bytes(HTML_PAGE.encode(), "text/html; charset=utf-8")
        elif self.path == "/events":
            self._sse()
        elif self.path == "/health":
            self._bytes(b'{"ok":true}', "application/json")
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        if self.path == "/navigate":
            try:
                length = int(self.headers.get("Content-Length", 0))
                body = json.loads(self.rfile.read(length)) if length else {}
            except (json.JSONDecodeError, ValueError):
                self._bytes(b'{"error":"bad json"}', "application/json", 400)
                return
            url = body.get("url", "").strip()
            if not url:
                self._bytes(b'{"error":"url required"}', "application/json", 400)
                return
            with _lock:
                _state["url"] = url
                _state["title"] = body.get("title", "")
                _state["ts"] = time.time()
            _event.set()
            self._bytes(json.dumps({"ok": True, "url": url}).encode(), "application/json")
        else:
            self.send_response(404)
            self.end_headers()

    def _bytes(self, data, ct, status=200):
        self.send_response(status)
        self.send_header("Content-Type", ct)
        self.send_header("Content-Length", len(data))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(data)

    def _sse(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Connection", "keep-alive")
        self.send_header("X-Accel-Buffering", "no")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        last_ts = 0
        try:
            while True:
                _event.wait(timeout=15)
                _event.clear()
                with _lock:
                    snap = dict(_state)
                if snap["ts"] > last_ts and snap["url"]:
                    last_ts = snap["ts"]
                    payload = json.dumps({
                        "url": snap["url"],
                        "title": snap["title"],
                        "ts": snap["ts"],
                    })
                    self.wfile.write(("event: navigate\ndata: %s\n\n" % payload).encode())
                    self.wfile.flush()
                else:
                    # keepalive
                    self.wfile.write(b": ping\n\n")
                    self.wfile.flush()
        except (BrokenPipeError, ConnectionResetError, OSError):
            pass

    def log_message(self, fmt, *args):
        sys.stderr.write("%s - %s\n" % (self.log_date_time_string(), fmt % args))


class ThreadedServer(ThreadingMixIn, HTTPServer):
    allow_reuse_address = True
    daemon_threads = True


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

def main():
    once = "--once" in sys.argv

    if once:
        port = is_server_running()
        if port is not None:
            print("Grafana relay already running: http://zion:%s" % port, file=sys.stderr)
            sys.exit(0)

    try:
        with open(pid_path(), "w") as f:
            f.write(str(os.getpid()))
    except OSError:
        pass

    server = None
    port_used = None
    for port in PORT_FALLBACKS:
        try:
            server = ThreadedServer((HOST, port), RelayHandler)
            port_used = port
            break
        except OSError as e:
            if e.errno != 98:
                raise
            continue

    if server is None:
        print("Grafana relay: could not bind to any of %s" % PORT_FALLBACKS, file=sys.stderr)
        sys.exit(1)

    print("Grafana relay: http://zion:%s" % port_used, file=sys.stderr)
    sys.stderr.flush()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    server.server_close()


if __name__ == "__main__":
    main()
