#!/usr/bin/env bash
# Hook: UserPromptSubmit — heartbeat de sessão interativa
# Cria/atualiza .live em .ephemeral/agents/zion_<hostname>_<session_short>/ (sessões interativas = Zion)
# Permite que o statusline conte sessões interativas ativas (TTL 900s)

input=$(cat)

SESSION_ID=$(echo "$input" | jq -r '.session_id // ""' 2>/dev/null)
[[ -z "$SESSION_ID" || "$SESSION_ID" == "null" ]] && exit 0

# Primeiros 12 chars do session_id como sufixo
SESSION_SHORT="${SESSION_ID:0:12}"
HOSTNAME_SAFE="${HOSTNAME:-unknown}"

AGENTS_DIR="/workspace/nixos/.ephemeral/agents"
AGENT_DIR="$AGENTS_DIR/zion_${HOSTNAME_SAFE}_${SESSION_SHORT}"

mkdir -p "$AGENT_DIR" 2>/dev/null || exit 0

# Atualiza .live com metadados
cat > "$AGENT_DIR/.live" <<EOF
started=$(date -u +%Y-%m-%dT%H:%M:%SZ)
session=$SESSION_ID
host=$HOSTNAME_SAFE
type=interactive
EOF
