#!/usr/bin/env bash
# Hook: SessionStart — injeta boot context pro Claude via stdout
# stdout → system-reminder (Claude vê)
# stderr → terminal do user (dashboard visual)

# ── Detecta workspace (container vs host) ────────────────────────
if [ -d "/workspace/host" ]; then
  WS="/workspace/host"
elif [ -d "/workspace" ] && [ -f "/workspace/CLAUDE.md" ]; then
  WS="/workspace"
else
  # host: resolve symlink real → stow/.claude/hooks/ → sobe 4 níveis
  _real="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "$0")"
  _dir="$(cd "$(dirname "$_real")/../../../.." 2>/dev/null && pwd)"
  [ -f "$_dir/CLAUDE.md" ] && WS="$_dir" || WS="$(pwd)"
fi

# Roda bootstrap (dashboard pro user via stderr)
BOOTSTRAP="$WS/scripts/bootstrap.sh"
if [ -x "$BOOTSTRAP" ]; then
  "$BOOTSTRAP" >&2
fi

# ── Boot context (stdout → Claude) ──────────────────────────────

# Flags (inline, sem precisar de tool calls)
PERSONALITY="ON"
[ -f "$WS/.ephemeral/personality-off" ] && PERSONALITY="OFF"
AUTOCOMMIT="OFF"
[ -f "$WS/.ephemeral/auto-commit" ] && AUTOCOMMIT="ON"
AUTOJARVIS="OFF"
[ -f "$WS/.ephemeral/auto-jarvis" ] && AUTOJARVIS="ON"

echo "BOOT: personality=$PERSONALITY autocommit=$AUTOCOMMIT autojarvis=$AUTOJARVIS"

# Persona content (inline — evita Read tool calls no boot)
if [ "$PERSONALITY" = "ON" ]; then
  SOUL="$WS/claudinho/SOUL.md"
  if [ -f "$SOUL" ]; then
    # Extract persona path from SOUL.md
    PERSONA_PATH=$(grep -m1 'Arquivo:' "$SOUL" | sed 's/.*`\(.*\)`.*/\1/')
    if [ -n "$PERSONA_PATH" ] && [ -f "$WS/$PERSONA_PATH" ]; then
      echo "---PERSONA---"
      cat "$WS/$PERSONA_PATH"
      echo "---/PERSONA---"
    elif [ -n "$PERSONA_PATH" ]; then
      echo "WARN: persona file not found: $WS/$PERSONA_PATH" >&2
    fi
  fi
  # DIRETRIZES
  if [ -f "$WS/claudinho/DIRETRIZES.md" ]; then
    echo "---DIRETRIZES---"
    cat "$WS/claudinho/DIRETRIZES.md"
    echo "---/DIRETRIZES---"
  fi
  # CLAUDE.md (project instructions)
  if [ -f "$WS/CLAUDE.md" ]; then
    echo "---CLAUDE.MD---"
    cat "$WS/CLAUDE.md"
    echo "---/CLAUDE.MD---"
  fi
  # SELF.md (diário)
  if [ -f "$WS/claudinho/SELF.md" ]; then
    echo "---SELF---"
    cat "$WS/claudinho/SELF.md"
    echo "---/SELF---"
  fi
fi
