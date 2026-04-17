# NixOS + vennon — root justfile
# Uso: just <recipe>
# Requer: just, nh, stow, docker

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

# ── Reverse proxy ──────────────────────────────────────────────────────────

# Sobe reverse proxy (docker)
proxy:
	docker compose -f vennon/docker/reverseproxy/docker-compose.yml -p vennon-dk-reverseproxy up -d

# ── vennon CLI ───────────────────────────────────────────────────────────────

# Compila e instala vennon Rust CLI em ~/.local/bin/vennon
install:
    cargo build --release --manifest-path vennon/rust/Cargo.toml -p vennon-cli
    install -m 755 vennon/rust/target/release/vennon {{nixos_dir}}/stow/.local/bin/vennon
    @# install -m 755 vennon/scripts/bootstrap-dashboard.sh {{nixos_dir}}/scripts/bootstrap.sh
    @echo "[just] vennon instalado em {{nixos_dir}}/stow/.local/bin/vennon"

# Atualiza só o bootstrap (vennon/scripts → scripts/)
bootstrap:
    @# install -m 755 vennon/scripts/bootstrap-dashboard.sh scripts/bootstrap.sh
    @echo "[just] bootstrap script não disponível"

# Build sem instalar
build-cli:
    cargo build --release --manifest-path vennon/rust/Cargo.toml -p vennon-cli

# Instala CLI bash legado (emergência)
install-bash:
    just --justfile vennon/bash/Justfile --working-directory vennon/bash install
