#!/usr/bin/env bash
# Hook: intercepta "startup" e mostra output direto (sem passar pelo LLM)
# Exit 2 = bloqueia o prompt, stderr = feedback pro usuário

set -euo pipefail

INPUT=$(cat)

if ! command -v jq &>/dev/null; then
  exit 0
fi

PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""')

if [[ "$PROMPT" == "startup" ]]; then
  for base in /workspace/nixos /workspace/host; do
    SCRIPT="$base/scripts/bootstrap.sh"
    if [[ -x "$SCRIPT" ]]; then
      "$SCRIPT" >&2
      break
    fi
  done
  exit 2
fi

exit 0
