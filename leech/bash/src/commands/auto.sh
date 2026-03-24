# Aciona o tick agent — toda a logica de dispatch esta no agent.md
leech_load_config

LEECH_DIR="${LEECH_ROOT:-${LEECH_NIXOS_DIR:-$HOME/nixos}/leech/self}"

# Resolve tick agent
TICK_AGENT="$LEECH_DIR/agents/tick/agent.md"
if [ ! -f "$TICK_AGENT" ]; then
  for _try in /workspace/self/agents/tick/agent.md \
              /workspace/mnt/leech/self/agents/tick/agent.md; do
    [ -f "$_try" ] && TICK_AGENT="$_try" && break
  done
fi

if [ ! -f "$TICK_AGENT" ]; then
  echo "[tick] agent.md nao encontrado"
  exit 1
fi

if [ -n "${args[--dry-run]:-}" ]; then
  echo "[tick] --dry-run: tick agent em $TICK_AGENT"
  exit 0
fi

_run_claude() {
  if [ "$(id -u)" = "0" ]; then
    setpriv --reuid=1000 --regid=1000 --keep-groups \
      env USER=claude LOGNAME=claude HOME=/home/claude \
      claude "$@"
  else
    claude "$@"
  fi
}

TICK_PROMPT=$(awk 'BEGIN{fm=0} /^---/{fm++; next} fm>=2{print}' "$TICK_AGENT")
HEADLESS=1 timeout 300 _run_claude \
  --permission-mode bypassPermissions \
  --model haiku \
  --max-turns 20 \
  -p "$TICK_PROMPT" \
  --add-dir "$HOME" \
  --add-dir /workspace/self \
  --add-dir /workspace/host \
  --add-dir /workspace/obsidian 2>&1 || echo "[tick] falhou"
