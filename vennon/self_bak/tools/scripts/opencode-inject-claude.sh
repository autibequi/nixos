#!/usr/bin/env bash
# Wrapper para OpenCode que injeta CLAUDE.md como contexto
# Uso: opencode-inject-claude.sh [args...]

set -euo pipefail

WORKSPACE="${WORKSPACE:-/workspace}"
CLAUDE_FILE="$WORKSPACE/CLAUDE.md"

# Se CLAUDE.md existe, injeta como contexto
if [[ -f "$CLAUDE_FILE" ]]; then
    # Lê CLAUDE.md e passa como contexto via stdin/variável
    export CLAUDE_CONTEXT="$(cat "$CLAUDE_FILE")"
fi

# Invoca OpenCode original com args passados
exec opencode "$@"
