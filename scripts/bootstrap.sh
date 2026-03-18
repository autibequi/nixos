#!/usr/bin/env bash
# CLAUDINHO startup — modular dashboard
# Fonte: zion/scripts/bootstrap-dashboard.sh — copiado para scripts/bootstrap.sh por make install / zion update
# Mounts sob /workspace: nixos, obsidian, logs, mount (não na raiz).
set -uo pipefail

# Limpa output anterior (docker compose up, etc.). Não limpar quando vamos
# passar o controle ao Claude Code (evita tela preta: claude não redesenha a tempo).
[[ -z "${BOOTSTRAP_SKIP_CLEAR:-}" ]] && printf '\033c'

# --- Init /workspace como git repo para Claude Code abrir aqui ---
[[ ! -d /workspace/.git ]] && git init /workspace >/dev/null 2>&1 || true

# --- Sync Claude configs from stow/.claude/ to ~/.claude/ ---
# NOTE: agents, commands, hooks, scripts, skills are mounted directly from
# zion/ via docker-compose volumes. Do NOT rm -rf or symlink them here —
# that would destroy the mount contents. Only sync loose config files.
for config_file in settings.json statusline.sh; do
  for base in /workspace/nixos /workspace/host; do
    src="$base/stow/.claude/$config_file"
    if [[ -f "$src" ]]; then
      cp "$src" "$HOME/.claude/$config_file" 2>/dev/null || true
      break
    fi
  done
done

# --- Load modules and render dashboard ---
BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/bootstrap" && pwd)"
source "$BOOTSTRAP_DIR/modules.sh"

# Quando source/. : retorna; quando executado: exit
[[ "${BASH_SOURCE[0]:-}" != "$0" ]] && return 0 || exit 0
