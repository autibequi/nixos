# NixOS — root justfile
# Uso: just <recipe>
# Requer: just, nh, stow

set shell := ["bash", "-c"]

nixos_dir := justfile_directory()

# Lista receitas disponíveis
default:
    @just --list

# ── NixOS ──────────────────────────────────────────────────────────────────

# Aplica config NixOS (nh os switch)
switch:
    nh os switch .

# Atualiza flake e aplica
update:
    nh os switch --update .

# ── Dotfiles ───────────────────────────────────────────────────────────────

# Injeta dotfiles via stow (limpa conflitos em .config/bardiel antes)
stow:
    #!/usr/bin/env bash
    set -euo pipefail
    for dir in agents commands hooks scripts skills; do
      link="$HOME/.claude/$dir"
      if [ -L "$link" ]; then
        target=$(readlink "$link")
        case "$target" in /workspace/*) echo "removing container symlink: $link"; rm -f "$link" ;; esac
      fi
    done
    # Only nuke .config/bardiel targets — leave hypr/waybar/etc alone (already stow-managed)
    { find stow/.config/bardiel -type f 2>/dev/null || true; } | while read -r src; do
      tgt="$HOME/${src#stow/}"
      { [ -e "$tgt" ] || [ -L "$tgt" ]; } && rm -f "$tgt" || true
    done
    stow --target="$HOME" --no-folding --adopt -S stow

# Remove e re-injeta dotfiles
restow:
    #!/usr/bin/env bash
    set -euo pipefail
    for dir in agents commands hooks scripts skills; do
      link="$HOME/.claude/$dir"
      if [ -L "$link" ]; then
        target=$(readlink "$link")
        case "$target" in /workspace/*) rm -f "$link" ;; esac
      fi
    done
    # Only nuke .config/bardiel targets — leave hypr/waybar/etc alone (already stow-managed)
    { find stow/.config/bardiel -type f 2>/dev/null || true; } | while read -r src; do
      tgt="$HOME/${src#stow/}"
      { [ -e "$tgt" ] || [ -L "$tgt" ]; } && rm -f "$tgt" || true
    done
    stow --target="$HOME" --no-folding --adopt -S stow
