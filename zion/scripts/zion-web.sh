#!/usr/bin/env bash
# zion-web — Watcher que abre URLs do agent no browser do host
# Roda no HOST. O agent escreve URLs em /tmp/zion-hive-mind/grafana-url.
# O watcher detecta mudanças e abre com xdg-open (browser padrão).
#
# Uso:
#   zion-web              # inicia watcher
#   zion-web --kill       # mata watcher
#   zion-web --status     # verifica

set -euo pipefail

URL_FILE="/tmp/zion-hive-mind/grafana-url"
# This path is the SAME from both host and container
# because the compose mounts /tmp/zion-hive-mind:/workspace/.hive-mind
# BUT from host perspective, the file is at /tmp/zion-hive-mind/grafana-url
PID_FILE="/tmp/zion-web.pid"

case "${1:-start}" in
  --kill|-k)
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      kill "$(cat "$PID_FILE")" && rm -f "$PID_FILE"
      echo "Watcher parado."
    else
      echo "Nenhum watcher rodando."
    fi
    exit 0
    ;;
  --status|-s)
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      echo "Watcher: RODANDO (PID $(cat "$PID_FILE"))"
      if [[ -f "$URL_FILE" ]]; then
        echo "Ultima URL: $(cat "$URL_FILE" | head -1)"
      fi
    else
      echo "Watcher: PARADO"
    fi
    exit 0
    ;;
esac

# Ensure hive-mind dir exists
mkdir -p "$(dirname "$URL_FILE")"

# Check for inotifywait
if ! command -v inotifywait >/dev/null 2>&1; then
  echo "ERRO: inotifywait nao encontrado."
  echo "Instale: nix-shell -p inotify-tools  (ou adicione ao NixOS)"
  exit 1
fi

# Kill existing watcher
if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "Matando watcher anterior..."
  kill "$(cat "$PID_FILE")" 2>/dev/null
fi

# Initialize file
touch "$URL_FILE"

echo "zion-web watcher iniciado."
echo "  Monitorando: $URL_FILE"
echo "  Browser: $(xdg-settings get default-web-browser 2>/dev/null || echo 'default')"
echo "  Kill: zion-web --kill"
echo ""

# Background watcher loop
(
  echo $BASHPID > "$PID_FILE"
  LAST_URL=""
  while true; do
    inotifywait -qq -e modify -e create "$URL_FILE" 2>/dev/null || sleep 1
    URL="$(head -1 "$URL_FILE" 2>/dev/null || true)"
    if [[ -n "$URL" && "$URL" != "$LAST_URL" ]]; then
      LAST_URL="$URL"
      echo "[$(date +%H:%M:%S)] Abrindo: $URL"
      xdg-open "$URL" 2>/dev/null &
    fi
  done
) &

disown
echo "Watcher rodando em background (PID $(cat "$PID_FILE"))."
