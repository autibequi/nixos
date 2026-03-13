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
  SCRIPT="/workspace/scripts/startup.sh"
  if [[ -x "$SCRIPT" ]]; then
    "$SCRIPT" >&2
    exit 2
  fi
fi

exit 0
