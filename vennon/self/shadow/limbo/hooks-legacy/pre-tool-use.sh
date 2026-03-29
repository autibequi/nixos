#!/usr/bin/env bash
# Hook: PreToolUse — Claude (stdout vazio) | Cursor/OPENCODE (JSON permission)
# ENGINE: CLAUDE | CURSOR | OPENCODE (exportado pelo wrapper ou ~/.vennon)

export ENGINE="${ENGINE:-CLAUDE}"

_vennon_FILE="${HOME:-/home/claude}/.vennon"
[ -f "$_vennon_FILE" ] || _vennon_FILE="/.vennon"
[ -f "$_vennon_FILE" ] && { set -a; source "$_vennon_FILE" 2>/dev/null || true; set +a; }
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
