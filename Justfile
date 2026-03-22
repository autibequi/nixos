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
    docker compose -f leech/dockerized/reverseproxy/docker-compose.yml -p leech-dk-reverseproxy up -d

# ── Leech CLI ───────────────────────────────────────────────────────────────

# Regenera leech CLI (bashly) + instala symlink + bootstrap
install:
    just --justfile leech/cli/Justfile --working-directory leech/cli install

# Regenera binário apenas
gen:
    just --justfile leech/cli/Justfile --working-directory leech/cli gen

# Atualiza só o bootstrap (leech/scripts → scripts/)
bootstrap:
    install -m 755 leech/scripts/bootstrap-dashboard.sh scripts/bootstrap.sh
    @echo "[just] scripts/bootstrap.sh atualizado"

# Simula boot session-start (dry run)
dry *args="":
    just --justfile leech/cli/Justfile --working-directory leech/cli dry {{args}}

# Lint dos scripts do CLI
lint:
    just --justfile leech/cli/Justfile --working-directory leech/cli lint

# Watch: regenera ao salvar src/
watch:
    just --justfile leech/cli/Justfile --working-directory leech/cli watch
