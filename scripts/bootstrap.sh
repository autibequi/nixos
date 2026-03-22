#!/usr/bin/env bash
# CLAUDINHO startup — modular dashboard
# Fonte: leech/scripts/bootstrap-dashboard.sh — copiado para scripts/bootstrap.sh por make install / leech update
# Mounts sob /workspace: nixos, obsidian, logs, mount (não na raiz).
set -uo pipefail

# Limpa output anterior (docker compose up, etc.). Não limpar quando vamos
# passar o controle ao Claude Code (evita tela preta: claude não redesenha a tempo).
[[ -z "${BOOTSTRAP_SKIP_CLEAR:-}" ]] && printf '\033c'

# --- Init /workspace como git repo para Claude Code abrir aqui ---
[[ ! -d /workspace/.git ]] && git init /workspace >/dev/null 2>&1 || true

# --- Auto-clean sessões antigas (manter últimas 100) — roda em background ---
(
  _proj="$HOME/.claude/projects/-workspace-mnt"
  _keep=100
  _total=$(ls "$_proj"/*.jsonl 2>/dev/null | wc -l)
  if [[ "$_total" -gt "$_keep" ]]; then
    _keep_ids=$(ls -t "$_proj"/*.jsonl 2>/dev/null | head -"$_keep" | xargs -I{} basename {} .jsonl)
    for _f in "$_proj"/*.jsonl; do
      _id=$(basename "$_f" .jsonl)
      echo "$_keep_ids" | grep -qx "$_id" || { rm -f "$_f"; rm -rf "$_proj/$_id"; }
    done
  fi
) &>/dev/null &

# --- Sync Claude skills from stow/.claude/ → ~/.claude/ ---
# Repo NixOS em /workspace/nixos (ou /workspace/host por symlink)
for dir in agents commands hooks scripts skills; do
  for base in /workspace/nixos /workspace/host; do
    src="$base/stow/.claude/$dir"
    if [[ -d "$src" ]]; then
      rm -rf "$HOME/.claude/$dir" 2>/dev/null || true
      ln -sfn "$src" "$HOME/.claude/$dir" 2>/dev/null || true
      break
    fi
  done
done

# --- Sync Claude configs from stow/.claude/ to ~/.claude/ ---
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
