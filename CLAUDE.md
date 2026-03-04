# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

```sh
# Apply configuration (main command)
sudo nixos-rebuild switch --flake .#nomad

# Build without switching (test for errors)
sudo nixos-rebuild build --flake .#nomad

# Update all flake inputs
nix --extra-experimental-features 'nix-command flakes' flake update

# Update a single flake input
nix --extra-experimental-features 'nix-command flakes' flake update nixpkgs

# Apply dotfiles via stow (from stow/ directory)
stow -d ~/projects/nixos/stow -t ~ .
```

## Architecture Overview

This is a flake-based NixOS configuration for an ASUS Zephyrus G14 (AMD Ryzen + NVIDIA RTX 4060 mobile).

**Entry points:**
- `flake.nix` — Defines inputs and the single output: `nixosConfigurations.nomad`
- `configuration.nix` — Lists all module imports (the module registry)
- `hardware.nix` — Hardware-specific UUIDs for boot/root/swap partitions (**git skip-worktree'd** — not committed, template only)

**Module layout:**
- `modules/core/` — Always-imported essentials: kernel tuning, Nix settings, packages, services, shell, fonts, hibernate
- `modules/` — Optional feature modules: hyprland, nvidia, asus, bluetooth, steam, ai, podman, work, virt
- `modules/gnome/`, `modules/cosmic.nix`, `modules/kde.nix` — Disabled DEs (commented out in configuration.nix)
- `stow/` — Dotfiles managed with GNU `stow`, symlinked into `~`

**Flake inputs pattern:**
- `nixpkgs` = stable (25.11), `nixpkgs-unstable` = unstable (passed as `unstable` arg)
- Modules receive `{ inputs, unstable, hyprland-git, ... }` via `specialArgs`
- To use an unstable package in a module: `unstable.pkgs.somePackage`
- Hyprland is pinned to v0.54.0; its plugins use `inputs.hyprland.follows`

## Key Conventions

**Enabling/disabling features:** Comment/uncomment import lines in `configuration.nix`. Disabled modules are kept as commented imports for easy re-enabling.

**hardware.nix is a template:** It contains partition UUIDs that are local-only. Use `git update-index --skip-worktree hardware.nix` to avoid accidentally committing local UUIDs. Use `--no-skip-worktree` to temporarily unskip when the template itself needs updating.

**Dotfiles vs NixOS config:** Application configs (Hyprland, Waybar, Zed, VS Code, etc.) live in `stow/.config/` and are managed by stow, not Home Manager. `home-manager` is a flake input but the home.nix module is disabled in favour of stow.

**Two-GPU setup:** NVIDIA is configured for PRIME offload (only active when explicitly requested), not always-on. AMD iGPU handles the display by default.
