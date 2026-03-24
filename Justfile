# NixOS + Leech — root justfile
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

# Injeta dotfiles via stow
stow:
    @for dir in agents commands hooks scripts skills; do \
        link="$HOME/.claude/$dir"; \
        if [ -L "$link" ]; then \
            target=$(readlink "$link"); \
            case "$target" in /workspace/*) echo "removing container symlink: $link"; rm -f "$link" ;; esac; \
        fi; \
    done
    stow --target=$HOME --no-folding --adopt -R stow

# Remove e re-injeta dotfiles
restow:
    @for dir in agents commands hooks scripts skills; do \
        link="$HOME/.claude/$dir"; \
        if [ -L "$link" ]; then \
            target=$(readlink "$link"); \
            case "$target" in /workspace/*) rm -f "$link" ;; esac; \
        fi; \
    done
    stow --target=$HOME --no-folding --adopt --override=file -R stow

# ── Reverse proxy ──────────────────────────────────────────────────────────

# Sobe reverse proxy (docker)
proxy:
	docker compose -f leech/docker/reverseproxy/docker-compose.yml -p leech-dk-reverseproxy up -d

# ── Leech CLI ───────────────────────────────────────────────────────────────

# Compila e instala leech Rust CLI em ~/.local/bin/leech
install:
    cargo build --release --manifest-path leech/rust/Cargo.toml -p leech-cli
    install -m 755 leech/rust/target/release/leech {{nixos_dir}}/stow/.local/bin/leech
    install -m 755 leech/scripts/bootstrap-dashboard.sh {{nixos_dir}}/scripts/bootstrap.sh
    @echo "[just] leech instalado em {{nixos_dir}}/stow/.local/bin/leech"

# Atualiza só o bootstrap (leech/scripts → scripts/)
bootstrap:
    install -m 755 leech/scripts/bootstrap-dashboard.sh scripts/bootstrap.sh
    @echo "[just] scripts/bootstrap.sh atualizado"

# Build sem instalar
build-cli:
    cargo build --release --manifest-path leech/rust/Cargo.toml -p leech-cli

# Instala CLI bash legado (emergência)
install-bash:
    just --justfile leech/bash/Justfile --working-directory leech/bash install
