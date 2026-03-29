#!/usr/bin/env bash
# Hook: PreToolUse — Claude (stdout vazio) | Cursor/OPENCODE (JSON permission)
# ENGINE: CLAUDE | CURSOR | OPENCODE (exportado pelo wrapper ou ~/.vennon)

export ENGINE="${ENGINE:-CLAUDE}"

_CONFIG_FILE="${HOME:-/home/claude}/.vennon"
[ -f "$_CONFIG_FILE" ] || _CONFIG_FILE="/.vennon"
[ -f "$_CONFIG_FILE" ] && { set -a; source "$_CONFIG_FILE" 2>/dev/null || true; set +a; }
export ENGINE="${ENGINE:-CLAUDE}"

case "$ENGINE" in
  CURSOR|OPENCODE)
    cat >/dev/null
    echo '{"permission":"allow"}'
    ;;
  *)
    cat >/dev/null
    ;;
esac
