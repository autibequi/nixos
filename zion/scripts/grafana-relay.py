#!/usr/bin/env python3
"""
Grafana Relay — Envia URLs para o browser do host via arquivo compartilhado.

O host roda `zion-web.sh` que monitora /tmp/zion-hive-mind/grafana-url.
Quando o agent escreve nesse arquivo, o host faz xdg-open no browser padrao.

Uso direto:
  python3 grafana-relay.py navigate "https://..." "Title"

Uso como servidor:
  python3 grafana-relay.py serve [--once]
  curl -X POST http://localhost:8780/navigate -d '{"url":"...","title":"..."}'

Status:
  python3 grafana-relay.py status
"""
import http.client
import json
import os
import socket
import sys
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
from socketserver import ThreadingMixIn

SERVER_PORT_FALLBACKS = [8780, 8781, 8782, 8783]
SERVER_HOST = "127.0.0.1"
HIVE_MIND = os.environ.get("HIVE_MIND", "/tmp/zion-hive-mind")
URL_FILE = os.path.join(HIVE_MIND, "grafana-url")


def navigate(url, title=""):
    """Write URL to shared file. Host watcher picks it up via inotifywait."""
    os.makedirs(os.path.dirname(URL_FILE), exist_ok=True)
    with open(URL_FILE, "w") as f:
        f.write(url + "\n")
    return True, "URL written to %s" % URL_FILE


def is_watcher_running():
    """Check if host watcher PID file exists and process is alive."""
    pid_file = "/tmp/zion-web.pid"
    # We can't check host PIDs from container, but we can check if the file exists
    # via hive-mind. Just check if URL_FILE dir exists.
    return os.path.isdir(HIVE_MIND)


# ---------------------------------------------------------------------------
# HTTP Server
# ---------------------------------------------------------------------------

_nav_history = []


class RelayHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            body = json.dumps({"ok": True, "hive_mind": os.path.isdir(HIVE_MIND)}).encode()
            self._bytes(body, "application/json")
        elif self.path == "/status":
            body = json.dumps({
                "hive_mind": os.path.isdir(HIVE_MIND),
                "url_file": URL_FILE,
                "history": _nav_history[-10:],
            }).encode()
            self._bytes(body, "application/json")
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

            title = body.get("title", "")
            ok, msg = navigate(url, title)

            entry = {"url": url, "title": title, "time": time.strftime("%H:%M:%S"), "ok": ok}
            _nav_history.append(entry)
            if len(_nav_history) > 50:
                _nav_history.pop(0)

            result = json.dumps({"ok": ok, "message": msg, "url": url}).encode()
            self._bytes(result, "application/json", 200 if ok else 502)
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

    def log_message(self, fmt, *args):
        sys.stderr.write("%s - %s\n" % (self.log_date_time_string(), fmt % args))


class ThreadedServer(ThreadingMixIn, HTTPServer):
    allow_reuse_address = True
    daemon_threads = True


def is_server_running():
    for port in SERVER_PORT_FALLBACKS:
        try:
            with socket.create_connection(("127.0.0.1", port), timeout=0.5):
                return port
        except (ConnectionRefusedError, OSError):
            pass
    return None


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def cmd_navigate(args):
    url = args[0] if args else ""
    title = args[1] if len(args) > 1 else ""
    if not url:
        print("Usage: grafana-relay.py navigate <url> [title]", file=sys.stderr)
        sys.exit(1)

    # Try server first
    port = is_server_running()
    if port:
        try:
            conn = http.client.HTTPConnection("127.0.0.1", port, timeout=3)
            body = json.dumps({"url": url, "title": title})
            conn.request("POST", "/navigate", body, {"Content-Type": "application/json"})
            resp = conn.getresponse()
            data = json.loads(resp.read().decode())
            conn.close()
            if data.get("ok"):
                print("OK: %s" % data.get("message", "sent"))
            else:
                print("FAIL: %s" % data.get("message", "?"), file=sys.stderr)
                sys.exit(1)
            return
        except Exception:
            pass

    # Direct file write
    ok, msg = navigate(url, title)
    if ok:
        print("OK: %s" % msg)
    else:
        print("FAIL: %s" % msg, file=sys.stderr)
        sys.exit(1)


def cmd_status():
    server = is_server_running()
    print("Hive mind:   %s" % ("OK (%s)" % HIVE_MIND if os.path.isdir(HIVE_MIND) else "NOT FOUND"))
    print("URL file:    %s" % URL_FILE)
    print("Relay HTTP:  %s" % ("OK (port %d)" % server if server else "NOT RUNNING"))
    if os.path.isfile(URL_FILE):
        with open(URL_FILE) as f:
            last = f.read().strip()
        print("Last URL:    %s" % (last[:80] if last else "(empty)"))
    print("\nHistory:" if _nav_history else "")
    for h in _nav_history[-5:]:
        print("  %s %s — %s" % (h["time"], h["title"], h["url"][:60]))


def cmd_serve(args):
    once = "--once" in args
    if once:
        port = is_server_running()
        if port:
            print("Relay already running on port %d" % port, file=sys.stderr)
            sys.exit(0)

    server = None
    port_used = None
    for port in SERVER_PORT_FALLBACKS:
        try:
            server = ThreadedServer((SERVER_HOST, port), RelayHandler)
            port_used = port
            break
        except OSError as e:
            if e.errno != 98:
                raise

    if server is None:
        print("Could not bind to any port in %s" % SERVER_PORT_FALLBACKS, file=sys.stderr)
        sys.exit(1)

    hive = "OK" if os.path.isdir(HIVE_MIND) else "MISSING"
    print("Grafana relay: http://localhost:%d (hive-mind: %s)" % (port_used, hive), file=sys.stderr)
    sys.stderr.flush()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    server.server_close()


def main():
    if len(sys.argv) < 2:
        print("Usage: grafana-relay.py <command> [args]")
        print("  navigate <url> [title]  — Open URL in host browser")
        print("  serve [--once]          — Start HTTP relay server")
        print("  status                  — Check relay status")
        sys.exit(1)

    cmd = sys.argv[1]
    rest = sys.argv[2:]

    if cmd == "navigate":
        cmd_navigate(rest)
    elif cmd == "serve":
        cmd_serve(rest)
    elif cmd == "status":
        cmd_status()
    else:
        print("Unknown command: %s" % cmd, file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
