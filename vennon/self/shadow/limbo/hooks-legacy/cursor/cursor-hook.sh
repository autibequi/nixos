#!/usr/bin/env bash
# Cursor Agent — único entrypoint (sessionStart / preToolUse / postToolUse)
# Scripts vennon partilhados: ../session-start.sh, ../pre-tool-use.sh, ../post-tool-use.sh
# hooks.json: .../vennon-hooks/cursor-hook.sh sessionStart
set -euo pipefail
export ENGINE=CURSOR

_HOOKS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_cmd="${1:-}"

case "$_cmd" in
  sessionStart|session-start)
    cat >/dev/null
    OUT="$(HOME="${HOME:-/home/claude}" USER="${USER:-claude}" LOGNAME="${LOGNAME:-claude}" \
      /bin/bash "$_HOOKS_ROOT/session-start.sh" 2>/dev/null || true)"
    printf '%s' "$OUT" | python3 -c 'import json,sys; print(json.dumps({"additional_context": sys.stdin.read()}))'
    ;;
  preToolUse|pre-tool)
    exec "$_HOOKS_ROOT/pre-tool-use.sh"
    ;;
  postToolUse|post-tool)
    exec "$_HOOKS_ROOT/post-tool-use.sh"
    ;;
  *)
    echo "cursor-hook: uso: sessionStart | preToolUse | postToolUse" >&2
    exit 1
    ;;
esac
