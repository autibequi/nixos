#!/usr/bin/env bash
# Hook: SessionStart — injeta boot context pro Claude via stdout
# stdout → system-reminder (Claude vê)
# stderr → terminal do user (dashboard visual)

# Roda bootstrap (dashboard pro user via stderr)
BOOTSTRAP="/workspace/scripts/bootstrap.sh"
if [ -x "$BOOTSTRAP" ]; then
  "$BOOTSTRAP" >&2
fi

# ── Boot context (stdout → Claude) ──────────────────────────────
WS="/workspace"

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
  SOUL="$WS/SOUL.md"
  if [ -f "$SOUL" ]; then
    # Extract persona path from SOUL.md
    PERSONA_PATH=$(grep -m1 'Arquivo:' "$SOUL" | sed 's/.*`\(.*\)`.*/\1/')
    if [ -n "$PERSONA_PATH" ] && [ -f "$WS/$PERSONA_PATH" ]; then
      echo "---PERSONA---"
      cat "$WS/$PERSONA_PATH"
      echo "---/PERSONA---"
    fi
  fi
  # DIRETRIZES
  if [ -f "$WS/DIRETRIZES.md" ]; then
    echo "---DIRETRIZES---"
    cat "$WS/DIRETRIZES.md"
    echo "---/DIRETRIZES---"
  fi
  # CLAUDE.md (project instructions)
  if [ -f "$WS/CLAUDE.md" ]; then
    echo "---CLAUDE.MD---"
    cat "$WS/CLAUDE.md"
    echo "---/CLAUDE.MD---"
  fi
  # SELF.md (diário)
  if [ -f "$WS/SELF.md" ]; then
    echo "---SELF---"
    cat "$WS/SELF.md"
    echo "---/SELF---"
  fi
fi
