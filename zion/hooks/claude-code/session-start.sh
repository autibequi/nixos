#!/usr/bin/env bash
# Hook: SessionStart — injeta boot context pro Claude via stdout
# stdout → system-reminder (Claude vê)
# stderr → terminal do user (dashboard visual)

# ── Detecta workspace (container vs host) ────────────────────────
# Mounts sob /workspace: nixos, obsidian, logs, mount. Repo NixOS em /workspace/nixos (ou /workspace/host por symlink).
if [ -d "/workspace/nixos" ] && [ -f "/workspace/nixos/CLAUDE.md" ]; then
  WS="/workspace/nixos"
elif [ -d "/workspace/host" ] && [ -f "/workspace/host/CLAUDE.md" ]; then
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

# API usage (universal — sempre injetar para controle de cota)
USAGE_BAR_SCRIPT="$WS/stow/.claude/scripts/usage-bar.sh"
if [ -x "$USAGE_BAR_SCRIPT" ]; then
  export WS
  "$USAGE_BAR_SCRIPT" 2>/dev/null || true
fi
if [ -f "$WS/.ephemeral/usage-bar.txt" ]; then
  echo "---API_USAGE---"
  cat "$WS/.ephemeral/usage-bar.txt"
  echo "---/API_USAGE---"
fi

# Persona content (inline — evita Read tool calls no boot). Personality files live in zion/system/
if [ "$PERSONALITY" = "ON" ]; then
  SOUL="$WS/zion/system/SOUL.md"
  if [ -f "$SOUL" ]; then
    PERSONA_PATH=$(grep -m1 'Arquivo:' "$SOUL" | sed 's/.*`\(.*\)`.*/\1/')
    if [ -n "$PERSONA_PATH" ] && [ -f "$WS/$PERSONA_PATH" ]; then
      echo "---PERSONA---"
      cat "$WS/$PERSONA_PATH"
      echo "---/PERSONA---"
    elif [ -n "$PERSONA_PATH" ]; then
      echo "WARN: persona file not found: $WS/$PERSONA_PATH" >&2
    fi
  fi
  if [ -f "$WS/zion/system/DIRETRIZES.md" ]; then
    echo "---DIRETRIZES---"
    cat "$WS/zion/system/DIRETRIZES.md"
    echo "---/DIRETRIZES---"
  fi
  # CLAUDE.OVERRIDE.md tem prioridade sobre CLAUDE.md (injetar primeiro)
  if [ -f "$WS/CLAUDE.OVERRIDE.md" ]; then
    echo "---CLAUDE.OVERRIDE.MD---"
    cat "$WS/CLAUDE.OVERRIDE.md"
    echo "---/CLAUDE.OVERRIDE.MD---"
  fi
  if [ -f "$WS/CLAUDE.md" ]; then
    echo "---CLAUDE.MD---"
    cat "$WS/CLAUDE.md"
    echo "---/CLAUDE.MD---"
  fi
  if [ -f "$WS/zion/system/SELF.md" ]; then
    echo "---SELF---"
    cat "$WS/zion/system/SELF.md"
    echo "---/SELF---"
  fi
fi
