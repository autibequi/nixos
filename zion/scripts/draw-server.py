#!/usr/bin/env python3
"""
Weblive Server — HTTP server on 127.0.0.1:8765.
- GET / → Draw: página que renderiza Mermaid + Markdown de content.md (SSE em /stream).
- GET /content → raw content.md.
- GET /stream → SSE para atualização ao vivo do Draw.
- GET /caminho → serve arquivos estáticos da pasta .weblive (ex.: /platformer/index.html).
"""
from http.server import HTTPServer, BaseHTTPRequestHandler
from socketserver import ThreadingMixIn
import os
import sys
import time
import urllib.parse

PORT_DEFAULT = 8765
HOST = "127.0.0.1"
PORT_FALLBACKS = [8765, 8766, 8767, 8768]


def weblive_root():
    """Diretório raiz servido (pasta .weblive)."""
    p = os.environ.get("ZION_WEBLIVE_ROOT")
    if p:
        return os.path.abspath(p)
    ws = os.environ.get("WORKSPACE", "")
    if ws:
        return os.path.join(ws, ".weblive")
    return os.path.join(os.getcwd(), ".weblive")


def content_path():
    p = os.environ.get("ZION_DRAW_CONTENT")
    if p:
        return os.path.abspath(p)
    return os.path.join(weblive_root(), "content.md")


def read_content():
    path = content_path()
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return ""
    except OSError:
        return ""


HTML_PAGE = """<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Draw</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:ital,opsz,wght@0,9..40,400;0,9..40,600;1,9..40,400&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
  <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
  <style>
    :root {
      --bg: #0f0f12;
      --surface: #18181c;
      --border: #2a2a30;
      --text: #e4e4e7;
      --text-muted: #71717a;
      --accent: #a78bfa;
      --accent-dim: #7c3aed;
      --live: #22c55e;
      --reconnect: #f59e0b;
    }
    * { box-sizing: border-box; }
    body {
      font-family: 'DM Sans', system-ui, sans-serif;
      background: var(--bg);
      color: var(--text);
      margin: 0;
      min-height: 100vh;
      line-height: 1.6;
    }
    .page {
      max-width: 52rem;
      margin: 0 auto;
      padding: 2rem 1.5rem 4rem;
    }
    .brand {
      font-size: 0.8125rem;
      font-weight: 600;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      color: var(--text-muted);
      margin-bottom: 1.5rem;
    }
    .brand span { color: var(--accent); }
    #content {
      min-height: 12rem;
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 1.75rem 2rem;
      box-shadow: 0 4px 24px rgba(0,0,0,0.25);
    }
    #content .md-block + .md-block { margin-top: 1.5rem; }
    #content :first-child { margin-top: 0; }
    #content :last-child { margin-bottom: 0; }
    #content h1 { font-size: 1.75rem; font-weight: 600; margin: 0 0 0.75rem; color: var(--text); }
    #content h2 { font-size: 1.25rem; font-weight: 600; margin: 1.5rem 0 0.5rem; color: var(--text); border-bottom: 1px solid var(--border); padding-bottom: 0.35rem; }
    #content h3 { font-size: 1.1rem; font-weight: 600; margin: 1.25rem 0 0.4rem; color: var(--text); }
    #content p { margin: 0 0 0.75rem; color: var(--text-muted); }
    #content ul, #content ol { margin: 0 0 0.75rem; padding-left: 1.5rem; color: var(--text-muted); }
    #content li { margin: 0.25rem 0; }
    #content pre {
      font-family: 'JetBrains Mono', monospace;
      font-size: 0.875rem;
      background: var(--bg);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 1rem 1.25rem;
      overflow-x: auto;
      margin: 0.75rem 0;
    }
    #content code {
      font-family: 'JetBrains Mono', monospace;
      font-size: 0.875em;
      background: var(--bg);
      color: var(--accent);
      padding: 0.2em 0.45em;
      border-radius: 4px;
    }
    #content pre code { background: none; color: var(--text); padding: 0; }
    #content blockquote {
      margin: 0.75rem 0;
      padding-left: 1rem;
      border-left: 3px solid var(--accent-dim);
      color: var(--text-muted);
    }
    #content a { color: var(--accent); text-decoration: none; }
    #content a:hover { text-decoration: underline; }
    #content hr { border: none; border-top: 1px solid var(--border); margin: 1.5rem 0; }
    .mermaid {
      margin: 1.25rem 0;
      padding: 1rem;
      background: var(--bg);
      border-radius: 8px;
      border: 1px solid var(--border);
    }
    #status {
      position: fixed;
      bottom: 1rem;
      right: 1rem;
      font-size: 0.6875rem;
      font-weight: 600;
      letter-spacing: 0.05em;
      text-transform: uppercase;
      padding: 0.35rem 0.65rem;
      border-radius: 6px;
      background: var(--surface);
      border: 1px solid var(--border);
      color: var(--text-muted);
    }
    #status.live { color: var(--live); border-color: rgba(34,197,94,0.35); background: rgba(34,197,94,0.08); }
    #status.reconnecting { color: var(--reconnect); border-color: rgba(245,158,11,0.35); background: rgba(245,158,11,0.08); }
  </style>
</head>
<body>
  <div class="page">
    <div class="brand"><span>Weblive</span> · Draw</div>
    <div id="content">Aguardando conteúdo…</div>
  </div>
  <div id="status">conectando…</div>
  <script>
    const contentEl = document.getElementById('content');
    const statusEl = document.getElementById('status');
    let lastRaw = '';

    function extractMermaidAndMarkdown(raw) {
      const parts = [];
      const re = /```mermaid\\s*([\\s\\S]*?)```/g;
      let idx = 0;
      let m;
      while ((m = re.exec(raw)) !== null) {
        if (m.index > idx) parts.push({ type: 'md', text: raw.slice(idx, m.index) });
        parts.push({ type: 'mermaid', text: m[1].trim() });
        idx = m.index + m[0].length;
      }
      if (idx < raw.length) parts.push({ type: 'md', text: raw.slice(idx) });
      return parts;
    }

    async function render(raw) {
      if (raw === undefined || raw === null) return;
      if (raw === lastRaw) return;
      lastRaw = raw;
      const parts = extractMermaidAndMarkdown(raw);
      let html = '';
      let mermaidId = 0;
      for (const p of parts) {
        if (p.type === 'md') {
          html += p.text ? '<div class="md-block">' + marked.parse(p.text) + '</div>' : '';
        } else {
          html += '<div class="mermaid" id="mermaid-' + (mermaidId++) + '">' + p.text + '</div>';
        }
      }
      contentEl.innerHTML = html || '<em>Aguardando conteúdo…</em>';
      if (typeof mermaid !== 'undefined') {
        try {
          await mermaid.run({ querySelector: '.mermaid', suppressErrors: true });
        } catch (e) { console.warn('mermaid', e); }
      }
    }

    function connect() {
      statusEl.textContent = 'conectando…';
      statusEl.className = '';
      const es = new EventSource('/stream');
      es.onopen = function() {
        statusEl.textContent = 'ao vivo';
        statusEl.className = 'live';
      };
      es.onmessage = function(ev) {
        render(ev.data);
      };
      es.onerror = function() {
        statusEl.textContent = 'reconectando…';
        statusEl.className = 'reconnecting';
        es.close();
        setTimeout(connect, 1500);
      };
    }

    if (typeof marked !== 'undefined') marked.setOptions({ gfm: true });
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
    });
    connect();
  </script>
</body>
</html>
"""


class DrawHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/" or self.path == "/index.html":
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(HTML_PAGE.encode("utf-8"))
            return
        if self.path == "/stream":
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Cache-Control", "no-cache")
            self.send_header("Connection", "keep-alive")
            self.send_header("X-Accel-Buffering", "no")
            self.end_headers()
            path = content_path()
            last_mtime = 0
            try:
                while True:
                    try:
                        st = os.stat(path)
                        mtime = st.st_mtime
                    except OSError:
                        mtime = 0
                    if mtime != last_mtime:
                        last_mtime = mtime
                        body = read_content()
                        for line in body.split("\n"):
                            self.wfile.write(("data: " + line + "\n").encode("utf-8"))
                        self.wfile.write(b"\n")
                        self.wfile.flush()
                    time.sleep(0.3)
            except (BrokenPipeError, ConnectionResetError, OSError):
                pass
            return
        if self.path == "/content":
            try:
                body = read_content()
            except Exception:
                self.send_response(500)
                self.send_header("Content-Type", "text/plain; charset=utf-8")
                self.end_headers()
                self.wfile.write(b"Error reading content file.")
                return
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.end_headers()
            self.wfile.write(body.encode("utf-8"))
            return
        # Servir pasta .weblive (arquivos estáticos)
        path = urllib.parse.unquote(self.path)
        if "?" in path:
            path = path.split("?")[0]
        if path.startswith("/"):
            path = path[1:]
        safe = os.path.normpath(path) if path else ""
        if not safe:
            self.send_response(404)
            self.end_headers()
            return
        if safe.startswith("..") or os.path.isabs(safe):
            self.send_response(403)
            self.end_headers()
            return
        full = os.path.join(weblive_root(), safe)
        if os.path.isdir(full):
            index = os.path.join(full, "index.html")
            if os.path.isfile(index):
                full = index
            else:
                self.send_response(404)
                self.end_headers()
                return
        if not os.path.isfile(full):
            self.send_response(404)
            self.end_headers()
            return
        ext = os.path.splitext(full)[1].lower()
        mime = {
            ".html": "text/html; charset=utf-8",
            ".htm": "text/html; charset=utf-8",
            ".css": "text/css; charset=utf-8",
            ".js": "application/javascript; charset=utf-8",
            ".json": "application/json; charset=utf-8",
            ".png": "image/png",
            ".jpg": "image/jpeg",
            ".jpeg": "image/jpeg",
            ".gif": "image/gif",
            ".svg": "image/svg+xml",
            ".ico": "image/x-icon",
            ".woff": "font/woff",
            ".woff2": "font/woff2",
        }.get(ext, "application/octet-stream")
        try:
            with open(full, "rb") as f:
                body = f.read()
        except OSError:
            self.send_response(500)
            self.end_headers()
            return
        self.send_response(200)
        self.send_header("Content-Type", mime)
        self.send_header("Content-Length", len(body))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        sys.stderr.write("%s - %s\n" % (self.log_date_time_string(), format % args))


class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    allow_reuse_address = True
    daemon_threads = True


def main():
    root = weblive_root()
    if root and not os.path.isdir(root):
        try:
            os.makedirs(root, exist_ok=True)
        except OSError:
            pass
    server = None
    port_used = None
    for port in PORT_FALLBACKS:
        try:
            server = ThreadedHTTPServer((HOST, port), DrawHandler)
            port_used = port
            break
        except OSError as e:
            if e.errno != 98:  # Address already in use
                raise
            continue
    if server is None:
        print("Draw server: could not bind to any of %s" % PORT_FALLBACKS, file=sys.stderr)
        sys.exit(1)
    print("Weblive server: http://zion:%s (root: %s)" % (port_used, weblive_root()), file=sys.stderr)
    sys.stderr.flush()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    server.server_close()


if __name__ == "__main__":
    main()
