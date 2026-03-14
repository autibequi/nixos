#!/usr/bin/env bash
# Hook: SessionStart — injeta prompt inicial para aquecer o motor
# stdout → vira contexto que o Claude vê e responde
set -euo pipefail

# Roda bootstrap (dashboard pro user via stderr)
BOOTSTRAP="/workspace/scripts/bootstrap.sh"
if [[ -x "$BOOTSTRAP" ]]; then
  "$BOOTSTRAP" >&2
fi

# Injeta prompt pro Claude processar
echo "O que temos pra hoje?"
