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
  <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
  <style>
    body { font-family: system-ui, sans-serif; margin: 1rem; max-width: 960px; }
    #content { min-height: 2rem; }
    .mermaid { margin: 1rem 0; }
    #content pre { background: #f4f4f4; padding: 0.5rem; overflow-x: auto; }
    #content code { background: #f4f4f4; padding: 0.1em 0.3em; }
    #status { position: fixed; bottom: 0.5rem; right: 0.5rem; font-size: 0.75rem; color: #666; }
    #status.live { color: #0a0; }
    #status.reconnecting { color: #a60; }
  </style>
</head>
<body>
  <div id="content">Aguardando conteúdo…</div>
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
    mermaid.initialize({ startOnLoad: false });
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
