#!/usr/bin/env python3
"""
Weblive Server v2 — Feed + Biblioteca de Desenhos.
- GET /            → Página principal: abas Feed / Desenhos
- GET /stream      → SSE — mtime watch do content.md
- GET /content     → Raw content.md
- GET /d/<slug>    → Renderiza drawing individual
- GET /api/drawings?q= → JSON lista de drawings (busca em título/tags/corpo)
- GET /<path>      → Arquivos estáticos de .weblive/

Estrutura:
  .weblive/
    content.md          ← feed live
    desenhos/           ← biblioteca de desenhos
      slug.md           ← drawing com frontmatter opcional
    .server.pid         ← PID do processo rodando

Uso:
  python3 draw-server.py          → sobe servidor
  python3 draw-server.py --once   → sobe só se não houver servidor; idempotente
"""
from http.server import HTTPServer, BaseHTTPRequestHandler
from socketserver import ThreadingMixIn
import json
import os
import re
import socket
import sys
import time
import urllib.parse

PORT_FALLBACKS = [8765, 8766, 8767, 8768, 8769, 8770, 8771, 8772]
HOST = "127.0.0.1"


# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

def weblive_root():
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


def drawings_dir():
    return os.path.join(weblive_root(), "desenhos")


def pid_path():
    return os.path.join(weblive_root(), ".server.pid")


# ---------------------------------------------------------------------------
# Data helpers
# ---------------------------------------------------------------------------

def read_content():
    path = content_path()
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except (FileNotFoundError, OSError):
        return ""


def parse_frontmatter(text):
    """Return (meta_dict, body) — meta is empty dict if no frontmatter."""
    meta = {}
    body = text
    if text.startswith("---\n") or text.startswith("---\r\n"):
        end = text.find("\n---", 4)
        if end != -1:
            fm = text[4:end]
            body = text[end + 4:].lstrip("\n\r")
            for line in fm.splitlines():
                if ":" in line:
                    k, v = line.split(":", 1)
                    meta[k.strip().lower()] = v.strip()
    return meta, body


def slugify_title(name):
    return name.replace("-", " ").replace("_", " ").title()


def load_drawing(slug):
    """Return (meta, body) or None."""
    if not re.match(r'^[\w\-]+$', slug):
        return None
    path = os.path.join(drawings_dir(), slug + ".md")
    try:
        with open(path, "r", encoding="utf-8") as f:
            text = f.read()
    except (FileNotFoundError, OSError):
        return None
    meta, body = parse_frontmatter(text)
    if "title" not in meta:
        meta["title"] = slugify_title(slug)
    return meta, body


def list_drawings(query=""):
    """Return list of drawing dicts, optionally filtered."""
    d = drawings_dir()
    results = []
    if not os.path.isdir(d):
        return results
    try:
        files = sorted(os.listdir(d))
    except OSError:
        return results
    q = query.lower().strip()
    for fname in files:
        if not fname.endswith(".md"):
            continue
        slug = fname[:-3]
        r = load_drawing(slug)
        if r is None:
            continue
        meta, body = r
        title = meta.get("title", slugify_title(slug))
        tags_raw = meta.get("tags", "")
        date = meta.get("date", "")
        tags = [t.strip() for t in tags_raw.split(",") if t.strip()]
        excerpt = re.sub(r'\s+', ' ', body[:120]).strip()
        if q:
            searchable = (title + " " + tags_raw + " " + body).lower()
            if q not in searchable:
                continue
        results.append({
            "slug": slug,
            "title": title,
            "tags": tags,
            "date": date,
            "excerpt": excerpt,
        })
    return results


# ---------------------------------------------------------------------------
# Smart startup
# ---------------------------------------------------------------------------

def is_server_running():
    """Return port number if any server is already running, else None."""
    for port in PORT_FALLBACKS:
        try:
            with socket.create_connection(("127.0.0.1", port), timeout=0.5):
                return port
        except (ConnectionRefusedError, OSError):
            pass
    return None


# ---------------------------------------------------------------------------
# HTML templates
# ---------------------------------------------------------------------------

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

RENDER_FN = """\
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

async function renderContent(raw, targetEl) {
  if (raw === undefined || raw === null) return;
  const parts = extractParts(raw);
  let html = '';
  for (const p of parts) {
    if (p.type === 'md') {
      html += p.text ? '<div class="md-block">' + marked.parse(p.text) + '</div>' : '';
    } else {
      html += '<div class="mermaid">' + p.text + '</div>';
    }
  }
  targetEl.innerHTML = html || '<em style="color:var(--text-muted)">Aguardando conteúdo…</em>';
  if (typeof mermaid !== 'undefined') {
    try { await mermaid.run({ nodes: targetEl.querySelectorAll('.mermaid'), suppressErrors: true }); }
    catch (e) { console.warn('mermaid', e); }
  }
}"""

COMMON_CSS = """\
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
.page { max-width: 52rem; margin: 0 auto; padding: 2rem 1.5rem 4rem; }
.brand {
  font-size: 0.8125rem; font-weight: 600; letter-spacing: 0.08em;
  text-transform: uppercase; color: var(--text-muted); margin-bottom: 1rem;
  display: flex; align-items: center; gap: 0.5rem;
}
.brand span { color: var(--accent); }
.status-dot {
  width: 7px; height: 7px; border-radius: 50%;
  background: var(--text-muted); display: inline-block;
}
.status-dot.live { background: var(--live); box-shadow: 0 0 6px var(--live); }
.status-dot.reconnecting { background: var(--reconnect); }
.md-content h1 { font-size: 1.75rem; font-weight: 600; margin: 0 0 0.75rem; color: var(--text); }
.md-content h2 { font-size: 1.25rem; font-weight: 600; margin: 1.5rem 0 0.5rem; color: var(--text); border-bottom: 1px solid var(--border); padding-bottom: 0.35rem; }
.md-content h3 { font-size: 1.1rem; font-weight: 600; margin: 1.25rem 0 0.4rem; color: var(--text); }
.md-content p { margin: 0 0 0.75rem; color: var(--text-muted); }
.md-content ul, .md-content ol { margin: 0 0 0.75rem; padding-left: 1.5rem; color: var(--text-muted); }
.md-content li { margin: 0.25rem 0; }
.md-content pre {
  font-family: 'JetBrains Mono', monospace; font-size: 0.875rem;
  background: var(--bg); border: 1px solid var(--border); border-radius: 8px;
  padding: 1rem 1.25rem; overflow-x: auto; margin: 0.75rem 0;
}
.md-content code {
  font-family: 'JetBrains Mono', monospace; font-size: 0.875em;
  background: var(--bg); color: var(--accent); padding: 0.2em 0.45em; border-radius: 4px;
}
.md-content pre code { background: none; color: var(--text); padding: 0; }
.md-content blockquote {
  margin: 0.75rem 0; padding-left: 1rem;
  border-left: 3px solid var(--accent-dim); color: var(--text-muted);
}
.md-content a { color: var(--accent); text-decoration: none; }
.md-content a:hover { text-decoration: underline; }
.md-content hr { border: none; border-top: 1px solid var(--border); margin: 1.5rem 0; }
.md-content .md-block + .md-block { margin-top: 1.5rem; }
.md-content :first-child { margin-top: 0; }
.md-content :last-child { margin-bottom: 0; }
.mermaid {
  margin: 1.25rem 0; padding: 1rem;
  background: var(--bg); border-radius: 8px; border: 1px solid var(--border);
}"""

HTML_MAIN = """<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Weblive</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:ital,opsz,wght@0,9..40,400;0,9..40,600;1,9..40,400&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
  <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
  <style>
    COMMON_CSS
    /* Tabs */
    .tabs {
      display: flex; gap: 0; margin-bottom: 1.5rem;
      border-bottom: 1px solid var(--border);
    }
    .tab-btn {
      background: none; border: none; cursor: pointer;
      padding: 0.6rem 1.25rem; font-family: inherit; font-size: 0.875rem;
      font-weight: 600; color: var(--text-muted); border-bottom: 2px solid transparent;
      margin-bottom: -1px; transition: color 0.15s, border-color 0.15s;
    }
    .tab-btn:hover { color: var(--text); }
    .tab-btn.active { color: var(--accent); border-bottom-color: var(--accent); }
    /* Feed panel */
    #panel-feed {
      min-height: 12rem; background: var(--surface);
      border: 1px solid var(--border); border-radius: 12px;
      padding: 1.75rem 2rem; box-shadow: 0 4px 24px rgba(0,0,0,0.25);
    }
    /* Drawings panel */
    .search-wrap { margin-bottom: 1.25rem; }
    .search-wrap input {
      width: 100%; background: var(--surface); border: 1px solid var(--border);
      border-radius: 8px; padding: 0.65rem 1rem; color: var(--text);
      font-family: inherit; font-size: 0.9375rem; outline: none;
    }
    .search-wrap input:focus { border-color: var(--accent); }
    .search-wrap input::placeholder { color: var(--text-muted); }
    #grid {
      display: grid; grid-template-columns: repeat(auto-fill, minmax(15rem, 1fr)); gap: 1rem;
    }
    .card {
      background: var(--surface); border: 1px solid var(--border); border-radius: 10px;
      padding: 1rem 1.125rem; cursor: pointer; transition: border-color 0.15s, transform 0.1s;
      text-decoration: none; display: block; color: inherit;
    }
    .card:hover { border-color: var(--accent); transform: translateY(-1px); }
    .card-title { font-weight: 600; font-size: 0.9375rem; margin-bottom: 0.4rem; color: var(--text); }
    .card-excerpt { font-size: 0.8125rem; color: var(--text-muted); margin-bottom: 0.6rem; line-height: 1.45; }
    .card-meta { display: flex; align-items: center; gap: 0.4rem; flex-wrap: wrap; }
    .tag {
      font-size: 0.6875rem; font-weight: 600; text-transform: uppercase;
      letter-spacing: 0.04em; padding: 0.2em 0.55em; border-radius: 4px;
      background: rgba(167,139,250,0.12); color: var(--accent); border: 1px solid rgba(167,139,250,0.2);
    }
    .card-date { font-size: 0.75rem; color: var(--text-muted); margin-left: auto; }
    #empty-state { color: var(--text-muted); font-size: 0.9375rem; padding: 1.5rem 0; }
    /* Status badge */
    #status {
      position: fixed; bottom: 1rem; right: 1rem;
      font-size: 0.6875rem; font-weight: 600; letter-spacing: 0.05em;
      text-transform: uppercase; padding: 0.35rem 0.65rem; border-radius: 6px;
      background: var(--surface); border: 1px solid var(--border); color: var(--text-muted);
    }
    #status.live { color: var(--live); border-color: rgba(34,197,94,0.35); background: rgba(34,197,94,0.08); }
    #status.reconnecting { color: var(--reconnect); border-color: rgba(245,158,11,0.35); background: rgba(245,158,11,0.08); }
  </style>
</head>
<body>
  <div class="page">
    <div class="brand">
      <span>Weblive</span>
      <div class="status-dot" id="status-dot"></div>
    </div>
    <div class="tabs">
      <button class="tab-btn active" id="btn-feed">Feed</button>
      <button class="tab-btn" id="btn-desenhos">Desenhos</button>
    </div>
    <div id="panel-feed" class="md-content">Aguardando conteúdo…</div>
    <div id="panel-desenhos" style="display:none">
      <div class="search-wrap">
        <input type="search" id="search" placeholder="Buscar por título, tag ou conteúdo…">
      </div>
      <div id="grid"></div>
      <div id="empty-state" style="display:none">Nenhum desenho encontrado.</div>
    </div>
  </div>
  <div id="status">conectando…</div>
  <script>
    RENDER_FN
    if (typeof marked !== 'undefined') marked.setOptions({ gfm: true });
    MERMAID_INIT

    // --- Tabs ---
    const panels = { feed: document.getElementById('panel-feed'), desenhos: document.getElementById('panel-desenhos') };
    const btns = { feed: document.getElementById('btn-feed'), desenhos: document.getElementById('btn-desenhos') };
    function switchTab(name) {
      Object.keys(panels).forEach(k => {
        panels[k].style.display = k === name ? '' : 'none';
        btns[k].classList.toggle('active', k === name);
      });
      if (name === 'desenhos') loadDrawings();
    }
    btns.feed.addEventListener('click', () => switchTab('feed'));
    btns.desenhos.addEventListener('click', () => switchTab('desenhos'));

    // --- Feed SSE ---
    const feedEl = document.getElementById('panel-feed');
    const statusEl = document.getElementById('status');
    const dotEl = document.getElementById('status-dot');
    let lastRaw = '';

    async function render(raw) {
      if (raw === undefined || raw === null || raw === lastRaw) return;
      lastRaw = raw;
      await renderContent(raw, feedEl);
    }

    function connect() {
      statusEl.textContent = 'conectando…'; statusEl.className = ''; dotEl.className = 'status-dot';
      const es = new EventSource('/stream');
      es.onopen = () => { statusEl.textContent = 'ao vivo'; statusEl.className = 'live'; dotEl.className = 'status-dot live'; };
      es.onmessage = ev => render(ev.data);
      es.onerror = () => {
        statusEl.textContent = 'reconectando…'; statusEl.className = 'reconnecting'; dotEl.className = 'status-dot reconnecting';
        es.close(); setTimeout(connect, 1500);
      };
    }
    connect();

    // --- Drawings ---
    let allDrawings = null;

    async function loadDrawings() {
      const q = (document.getElementById('search').value || '').trim();
      const url = '/api/drawings' + (q ? '?q=' + encodeURIComponent(q) : '');
      try {
        const res = await fetch(url);
        allDrawings = await res.json();
      } catch (e) {
        allDrawings = [];
      }
      renderGrid(allDrawings);
    }

    function renderGrid(drawings) {
      const grid = document.getElementById('grid');
      const empty = document.getElementById('empty-state');
      if (!drawings || drawings.length === 0) {
        grid.innerHTML = '';
        empty.style.display = '';
        return;
      }
      empty.style.display = 'none';
      grid.innerHTML = drawings.map(d => {
        const tags = (d.tags || []).map(t => '<span class="tag">' + escHtml(t) + '</span>').join('');
        return '<a class="card" href="/d/' + escHtml(d.slug) + '" target="_blank">' +
          '<div class="card-title">' + escHtml(d.title) + '</div>' +
          (d.excerpt ? '<div class="card-excerpt">' + escHtml(d.excerpt) + '</div>' : '') +
          '<div class="card-meta">' + tags + (d.date ? '<span class="card-date">' + escHtml(d.date) + '</span>' : '') + '</div>' +
          '</a>';
      }).join('');
    }

    function escHtml(s) {
      return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
    }

    let searchTimer;
    document.getElementById('search').addEventListener('input', () => {
      clearTimeout(searchTimer);
      searchTimer = setTimeout(loadDrawings, 250);
    });
  </script>
</body>
</html>
""".replace("    COMMON_CSS", COMMON_CSS).replace("    RENDER_FN", RENDER_FN).replace("    MERMAID_INIT", MERMAID_INIT)

DRAWING_PAGE_TMPL = """<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{title} — Weblive</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:ital,opsz,wght@0,9..40,400;0,9..40,600;1,9..40,400&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
  <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
  <style>
    COMMON_CSS
    .drawing-header {{
      margin-bottom: 1.5rem; padding-bottom: 1rem; border-bottom: 1px solid var(--border);
    }}
    .back-btn {{
      display: inline-flex; align-items: center; gap: 0.35rem;
      font-size: 0.8125rem; font-weight: 600; color: var(--text-muted);
      text-decoration: none; margin-bottom: 1rem; transition: color 0.15s;
    }}
    .back-btn:hover {{ color: var(--accent); }}
    .drawing-title {{ font-size: 1.75rem; font-weight: 600; margin: 0 0 0.5rem; color: var(--text); }}
    .drawing-meta {{ display: flex; align-items: center; gap: 0.4rem; flex-wrap: wrap; }}
    .tag {{
      font-size: 0.6875rem; font-weight: 600; text-transform: uppercase;
      letter-spacing: 0.04em; padding: 0.2em 0.55em; border-radius: 4px;
      background: rgba(167,139,250,0.12); color: var(--accent); border: 1px solid rgba(167,139,250,0.2);
    }}
    .drawing-date {{ font-size: 0.8125rem; color: var(--text-muted); }}
    #content {{
      background: var(--surface); border: 1px solid var(--border); border-radius: 12px;
      padding: 1.75rem 2rem; box-shadow: 0 4px 24px rgba(0,0,0,0.25);
    }}
  </style>
</head>
<body>
  <div class="page">
    <div class="brand"><span>Weblive</span> · Desenhos</div>
    <div class="drawing-header">
      <a class="back-btn" href="/?tab=desenhos">← Voltar</a>
      <div class="drawing-title">{title_esc}</div>
      <div class="drawing-meta">{tags_html}{date_html}</div>
    </div>
    <div id="content" class="md-content">Carregando…</div>
  </div>
  <script>
    RENDER_FN
    if (typeof marked !== 'undefined') marked.setOptions({{ gfm: true }});
    MERMAID_INIT
    const raw = {body_json};
    renderContent(raw, document.getElementById('content'));
  </script>
</body>
</html>
""".replace("    COMMON_CSS", COMMON_CSS).replace("    RENDER_FN", RENDER_FN).replace("    MERMAID_INIT", MERMAID_INIT)


def build_drawing_page(meta, body):
    def esc(s):
        return (str(s)
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace('"', "&quot;"))

    title = meta.get("title", "Desenho")
    tags = [t.strip() for t in meta.get("tags", "").split(",") if t.strip()]
    date = meta.get("date", "")
    tags_html = "".join('<span class="tag">%s</span>' % esc(t) for t in tags)
    date_html = ('<span class="drawing-date">%s</span>' % esc(date)) if date else ""

    return DRAWING_PAGE_TMPL.format(
        title=esc(title),
        title_esc=esc(title),
        tags_html=tags_html,
        date_html=date_html,
        body_json=json.dumps(body),
    )


# ---------------------------------------------------------------------------
# HTTP handler
# ---------------------------------------------------------------------------

class DrawHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        qs = urllib.parse.parse_qs(parsed.query)

        if path in ("/", "/index.html"):
            self._serve_bytes(HTML_MAIN.encode("utf-8"), "text/html; charset=utf-8")
            return

        if path == "/stream":
            self._serve_sse()
            return

        if path == "/content":
            self._serve_bytes(read_content().encode("utf-8"), "text/plain; charset=utf-8")
            return

        if path == "/api/drawings":
            q = qs.get("q", [""])[0]
            data = list_drawings(q)
            self._serve_bytes(json.dumps(data).encode("utf-8"), "application/json; charset=utf-8")
            return

        if path.startswith("/d/"):
            slug = path[3:].strip("/")
            result = load_drawing(slug)
            if result is None:
                self.send_response(404)
                self.send_header("Content-Type", "text/plain; charset=utf-8")
                self.end_headers()
                self.wfile.write(b"Drawing not found.")
                return
            meta, body = result
            html = build_drawing_page(meta, body)
            self._serve_bytes(html.encode("utf-8"), "text/html; charset=utf-8")
            return

        # Static files from .weblive/
        self._serve_static(urllib.parse.unquote(path))

    def _serve_bytes(self, data, content_type, status=200):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", len(data))
        self.end_headers()
        self.wfile.write(data)

    def _serve_sse(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Connection", "keep-alive")
        self.send_header("X-Accel-Buffering", "no")
        self.end_headers()
        cpath = content_path()
        last_mtime = 0
        try:
            while True:
                try:
                    mtime = os.stat(cpath).st_mtime
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

    def _serve_static(self, path):
        if "?" in path:
            path = path.split("?")[0]
        if path.startswith("/"):
            path = path[1:]
        safe = os.path.normpath(path) if path else ""
        if not safe or safe.startswith("..") or os.path.isabs(safe):
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
            ".htm":  "text/html; charset=utf-8",
            ".css":  "text/css; charset=utf-8",
            ".js":   "application/javascript; charset=utf-8",
            ".json": "application/json; charset=utf-8",
            ".png":  "image/png",
            ".jpg":  "image/jpeg",
            ".jpeg": "image/jpeg",
            ".gif":  "image/gif",
            ".svg":  "image/svg+xml",
            ".ico":  "image/x-icon",
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
        self._serve_bytes(body, mime)

    def log_message(self, format, *args):
        sys.stderr.write("%s - %s\n" % (self.log_date_time_string(), format % args))


class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
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
            print("Weblive server already running: http://zion:%s" % port, file=sys.stderr)
            sys.exit(0)

    root = weblive_root()
    for d in [root, drawings_dir()]:
        if d and not os.path.isdir(d):
            try:
                os.makedirs(d, exist_ok=True)
            except OSError:
                pass

    try:
        with open(pid_path(), "w") as f:
            f.write(str(os.getpid()))
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
            if e.errno != 98:
                raise
            continue

    if server is None:
        print("Draw server: could not bind to any of %s" % PORT_FALLBACKS, file=sys.stderr)
        sys.exit(1)

    print("Weblive server: http://zion:%s (root: %s)" % (port_used, root), file=sys.stderr)
    sys.stderr.flush()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    server.server_close()


if __name__ == "__main__":
    main()
