## [@] zion web — Chromium relay com CDP

CDP_PORT="${args[--port]:-9222}"
PROFILE_DIR="/tmp/zion-web-relay"

if [[ "${args[--kill]}" ]]; then
  echo "Matando Chromium relay..."
  pkill -f "user-data-dir=$PROFILE_DIR" 2>/dev/null && echo "OK" || echo "Nenhum processo encontrado"
  exit 0
fi

# Check if already running
if curl -s "http://localhost:$CDP_PORT/json/version" >/dev/null 2>&1; then
  echo "Chromium relay já rodando na porta $CDP_PORT"
  curl -s "http://localhost:$CDP_PORT/json/version" | python3 -m json.tool 2>/dev/null || true
  echo ""
  echo "Para matar: zion web --kill"
  exit 0
fi

# Find chromium binary
CHROMIUM=""
for bin in chromium chromium-browser google-chrome-stable google-chrome; do
  if command -v "$bin" >/dev/null 2>&1; then
    CHROMIUM="$bin"
    break
  fi
done

if [[ -z "$CHROMIUM" ]]; then
  echo "ERRO: Nenhum Chromium/Chrome encontrado no PATH"
  echo "Instale via: nix-shell -p chromium"
  exit 1
fi

echo "Iniciando $CHROMIUM com CDP na porta $CDP_PORT..."
echo "Perfil: $PROFILE_DIR (anonimo/isolado)"
echo ""

# Launch chromium with remote debugging
"$CHROMIUM" \
  --remote-debugging-port="$CDP_PORT" \
  --user-data-dir="$PROFILE_DIR" \
  --no-first-run \
  --no-default-browser-check \
  --disable-background-networking \
  --disable-sync \
  "about:blank" &

disown

# Wait for CDP to be ready
for i in $(seq 1 10); do
  if curl -s "http://localhost:$CDP_PORT/json/version" >/dev/null 2>&1; then
    echo "Chromium relay pronto!"
    echo "  CDP:  http://localhost:$CDP_PORT"
    echo "  Tabs: http://localhost:$CDP_PORT/json"
    echo ""
    echo "O agent agora pode controlar o browser."
    echo "Para matar: zion web --kill"
    exit 0
  fi
  sleep 0.5
done

echo "AVISO: Chromium iniciou mas CDP não respondeu em 5s"
echo "Pode estar carregando. Tente: curl http://localhost:$CDP_PORT/json/version"
