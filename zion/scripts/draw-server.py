#!/usr/bin/env python3
"""
Zion Draw Server — HTTP server on 127.0.0.1:8765.
Serves a single page that renders Mermaid + Markdown from a content file.
GET / → HTML with Mermaid.js + marked.js, SSE em /stream (tempo real).
GET /stream → Server-Sent Events: envia conteúdo quando o arquivo muda.
GET /content → raw content (fallback).
Agent writes to the content file; no POST needed.
"""
from http.server import HTTPServer, BaseHTTPRequestHandler
from socketserver import ThreadingMixIn
import os
import sys
import time

PORT = 8765
HOST = "127.0.0.1"


def content_path():
    p = os.environ.get("ZION_DRAW_CONTENT")
    if p:
        return os.path.abspath(p)
    ws = os.environ.get("WORKSPACE", "")
    if ws:
        return os.path.join(ws, ".zion-draw", "content.md")
    return os.path.join(os.getcwd(), ".zion-draw", "content.md")


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
  <title>Zion Draw</title>
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
        self.send_response(404)
        self.end_headers()

    def log_message(self, format, *args):
        sys.stderr.write("%s - %s\n" % (self.log_date_time_string(), format % args))


class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True


def main():
    content_dir = os.path.dirname(content_path())
    if content_dir and not os.path.isdir(content_dir):
        try:
            os.makedirs(content_dir, exist_ok=True)
        except OSError:
            pass
    server = ThreadedHTTPServer((HOST, PORT), DrawHandler)
    print("Zion Draw server: http://%s:%s (content: %s)" % (HOST, PORT, content_path()), file=sys.stderr)
    sys.stderr.flush()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    server.server_close()


if __name__ == "__main__":
    main()
