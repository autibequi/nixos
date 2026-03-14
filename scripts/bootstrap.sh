#!/usr/bin/env bash
# CLAUDINHO startup — modular dashboard
set -euo pipefail

# Limpa output anterior (docker compose up, etc.)
printf '\033c'

# --- Ensure agent symlinks in ~/.claude/agents/ ---
mkdir -p ~/.claude/agents 2>/dev/null || true
for agent_dir in /workspace/stow/.claude/agents/*/; do
  agent_name=$(basename "$agent_dir")
  target_link="$HOME/.claude/agents/$agent_name"
  if [[ ! -L "$target_link" ]] || [[ $(readlink "$target_link" 2>/dev/null || echo "") != "$agent_dir" ]]; then
    rm -f "$target_link" 2>/dev/null || true
    ln -s "$agent_dir" "$target_link" 2>/dev/null || true
  fi
done

# --- Sync Claude configs from stow/.claude/ to ~/.claude/ ---
for config_file in settings.json statusline.sh; do
  src="/workspace/stow/.claude/$config_file"
  dst="$HOME/.claude/$config_file"
  [[ -f "$src" ]] && cp "$src" "$dst" 2>/dev/null || true
done

# --- Load modules and render dashboard ---
BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/bootstrap" && pwd)"
source "$BOOTSTRAP_DIR/modules.sh"

# Quando source/. : retorna; quando executado: exit
[[ "${BASH_SOURCE[0]:-}" != "$0" ]] && return 0 || exit 0
