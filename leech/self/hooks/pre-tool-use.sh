#!/usr/bin/env bash
# Hook: PreToolUse — Claude (stdout vazio) | Cursor/OPENCODE (JSON permission)
# ENGINE: CLAUDE | CURSOR | OPENCODE (exportado pelo wrapper ou ~/.leech)

export ENGINE="${ENGINE:-CLAUDE}"

_LEECH_FILE="${HOME:-/home/claude}/.leech"
[ -f "$_LEECH_FILE" ] || _LEECH_FILE="/.leech"
[ -f "$_LEECH_FILE" ] && { set -a; source "$_LEECH_FILE" 2>/dev/null || true; set +a; }
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
