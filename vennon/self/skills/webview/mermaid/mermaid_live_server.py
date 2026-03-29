#!/usr/bin/env python3
"""Espelho em Python de mermaid-live-server.mjs (sem dependência Node)."""
from __future__ import annotations

import argparse
import json
import os
import threading
import time
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
from typing import ClassVar
from urllib.parse import urlparse

MIME = {
    ".html": "text/html; charset=utf-8",
    ".js": "text/javascript; charset=utf-8",
    ".css": "text/css; charset=utf-8",
    ".mmd": "text/plain; charset=utf-8",
    ".svg": "image/svg+xml",
    ".json": "application/json; charset=utf-8",
}


class LiveHandler(SimpleHTTPRequestHandler):
    server_version = "MermaidLive/1.0"
    clients: ClassVar[set] = set()
    clients_lock: ClassVar[threading.Lock] = threading.Lock()
    watch_file: ClassVar[Path] = Path("diagram.mmd")
    last_mtime: ClassVar[float | None] = None
    last_sent: ClassVar[str] = ""

    def log_message(self, fmt: str, *args) -> None:
        return

    def _broadcast(self, text: str) -> None:
        payload = json.dumps({"text": text or ""})
        chunk = f"data: {payload}\n\n".encode()
        with LiveHandler.clients_lock:
            dead = []
            for wfile in LiveHandler.clients:
                try:
                    wfile.write(chunk)
                    wfile.flush()
                except OSError:
                    dead.append(wfile)
            for w in dead:
                LiveHandler.clients.discard(w)

    def _read_file(self) -> str:
        p = LiveHandler.watch_file
        try:
            return p.read_text(encoding="utf-8")
        except OSError:
            return ""

    def do_POST(self) -> None:
        u = urlparse(self.path)
        if u.path != "/mermaid-push":
            self.send_error(404)
            return
        n = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(min(n, 2_000_000)).decode("utf-8", errors="replace")
        p = LiveHandler.watch_file
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(body, encoding="utf-8")
        LiveHandler.last_sent = body
        self._broadcast(body)
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()

    def do_GET(self) -> None:
        u = urlparse(self.path)
        if u.path == "/mermaid-live":
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream; charset=utf-8")
            self.send_header("Cache-Control", "no-cache, no-transform")
            self.send_header("Connection", "keep-alive")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            wfile = self.wfile
            with LiveHandler.clients_lock:
                LiveHandler.clients.add(wfile)
            try:
                text = self._read_file()
                payload = json.dumps({"text": text})
                wfile.write(f"data: {payload}\n\n".encode())
                wfile.flush()
                # manter conexão aberta (heartbeats evitam proxies cortarem)
                while True:
                    time.sleep(25)
                    wfile.write(b": ping\n\n")
                    wfile.flush()
            except (BrokenPipeError, ConnectionResetError, OSError):
                pass
            finally:
                with LiveHandler.clients_lock:
                    LiveHandler.clients.discard(wfile)
            return
        return SimpleHTTPRequestHandler.do_GET(self)

    def guess_type(self, path: str) -> str:
        ext = Path(path).suffix.lower()
        return MIME.get(ext, "application/octet-stream")


def poll_thread(watch: Path) -> None:
    handler = LiveHandler
    handler.watch_file = watch
    while True:
        time.sleep(0.35)
        try:
            st = watch.stat()
            m = st.st_mtime
        except OSError:
            continue
        if handler.last_mtime is None:
            handler.last_mtime = m
            continue
        if m != handler.last_mtime:
            handler.last_mtime = m
            text = watch.read_text(encoding="utf-8")
            if text == handler.last_sent:
                continue
            handler.last_sent = text
            payload = json.dumps({"text": text})
            chunk = f"data: {payload}\n\n".encode()
            with handler.clients_lock:
                dead = []
                for wfile in handler.clients:
                    try:
                        wfile.write(chunk)
                        wfile.flush()
                    except OSError:
                        dead.append(wfile)
                for w in dead:
                    handler.clients.discard(w)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--file", default="diagram.mmd", type=Path)
    ap.add_argument("--static", dest="static_root", default=".", type=Path)
    ap.add_argument("--port", type=int, default=9876)
    ap.add_argument("--bind", default="127.0.0.1")
    args = ap.parse_args()

    root = args.static_root.resolve()
    watch = args.file.resolve()
    watch.parent.mkdir(parents=True, exist_ok=True)
    if not watch.exists():
        watch.write_text(
            "%%{init: {'theme': 'dark'}}%%\nflowchart TD\n  A[Live] --> B[OK]\n",
            encoding="utf-8",
        )

    LiveHandler.watch_file = watch
    LiveHandler.last_sent = watch.read_text(encoding="utf-8")
    try:
        LiveHandler.last_mtime = watch.stat().st_mtime
    except OSError:
        LiveHandler.last_mtime = None
    os.chdir(root)

    t = threading.Thread(target=poll_thread, args=(watch,), daemon=True)
    t.start()

    httpd = ThreadingHTTPServer((args.bind, args.port), LiveHandler)
    print(
        f"mermaid-live http://{args.bind}:{args.port}/  file={watch}  static={root}",
        flush=True,
    )
    print("  SSE GET /mermaid-live   POST /mermaid-push   abrir página com ?live=1", flush=True)
    httpd.serve_forever()


if __name__ == "__main__":
    main()
