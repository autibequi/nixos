#!/usr/bin/env bash
# CLAUDINHO startup — modular dashboard
set -uo pipefail

# Limpa output anterior (docker compose up, etc.)
printf '\033c'

# --- Sync Claude skills from stow/.claude/ → ~/.claude/ ---
for dir in agents commands hooks scripts skills; do
  src="/workspace/host/stow/.claude/$dir"
  dst="$HOME/.claude/$dir"
  if [[ -d "$src" ]]; then
    rm -rf "$dst" 2>/dev/null || true
    ln -sfn "$src" "$dst" 2>/dev/null || true
  fi
done

# --- Sync Claude configs from stow/.claude/ to ~/.claude/ ---
for config_file in settings.json statusline.sh; do
  src="/workspace/host/stow/.claude/$config_file"
  dst="$HOME/.claude/$config_file"
  [[ -f "$src" ]] && cp "$src" "$dst" 2>/dev/null || true
done

# --- Load modules and render dashboard ---
BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/bootstrap" && pwd)"
source "$BOOTSTRAP_DIR/modules.sh"

# Quando source/. : retorna; quando executado: exit
[[ "${BASH_SOURCE[0]:-}" != "$0" ]] && return 0 || exit 0
