# NixOS + vennon

Flake-based NixOS configuration for an ASUS Zephyrus G14 (AMD Ryzen + NVIDIA RTX 4060 mobile), with vennon (agent launcher + container) and Puppy workers (background task runners).

## Architecture

```mermaid
graph TB
    USER(("user"))
    CHROME(["Chrome<br/>CDP relay"])

    subgraph CONTAINERS["vennon Containers"]
        direction LR
        L["vennon"]
        subgraph APP["Project Containers"]
            direction LR
            MONO["monolito"] ~~~ BO["bo"] ~~~ FRONT["front-student"]
        end
    end

    subgraph HOST["Host"]
        VOLS["/self  ·  /obsidian  ·  /logs  ·  ~/.vennon"]
        PROJ[("~/projects/estrategia")]
    end

    USER -->|multiple agent instances| L
    USER --> APP
    CHROME -.->|relay| L
    VOLS --> CONTAINERS
    CONTAINERS --> PROJ
```

## Structure

```
flake.nix            # Flake inputs and nixosConfigurations.nomad output
configuration.nix    # Module registry (enable/disable features here)
hardware.nix         # Partition UUIDs (local-only, git skip-worktree'd)

vennon/               # vennon system (agent launcher + containers)
  bash/              # Bashly CLI source (vennon command)
  docker/            # Docker compose files per service
    vennon/           # vennon container + docker-proxy
    monolito/        # Monolito (Go API)
    bo-container/    # Bo (Vue/Quasar)
    front-student/   # Front-student (Nuxt)
    reverseproxy/    # Nginx reverse proxy
  rust/              # Rust CLI entry point
  self/              # vennon engine: skills, hooks, agents, scripts, commands

modules/             # NixOS modules
  core/              # Essential (kernel, nix, packages, services, shell, fonts)
  hyprland.nix       # Hyprland compositor
  nvidia.nix         # NVIDIA PRIME offload (AMD iGPU as default)
  asus.nix           # ASUS Zephyrus hardware support
  docker.nix         # Docker daemon
  vennon-tick.nix     # systemd timer for vennon tick

scripts/             # Host scripts (bootstrap, dashboards, utilities)

stow/                # Dotfiles managed with GNU stow (symlinked into ~)
  scripts/           # Shell scripts → ~/scripts
  assets/            # Wallpapers, icons
```

## Flake Inputs

- **nixpkgs**: NixOS 25.11 (stable)
- **nixpkgs-unstable**: unstable channel (available as `unstable` in modules)
- **chaotic**: CachyOS kernel
- **hyprland**: pinned to v0.54.0
- **nixos-hardware**: ASUS Zephyrus hardware support
- **zen-browser**, **zed**, **isd**, **voxtype**, **nixified-ai**, **antigravity-nix**

## Commands

```sh
vennon switch         # Apply NixOS configuration (nh os switch)
vennon switch test    # Build and test without switching
vennon switch boot    # Apply on next boot
vennon stow           # Deploy dotfiles (stow -d ~/nixos/stow -t ~ .)
vennon update         # Regenerate vennon CLI (bashly generate)
vennon man            # Full command reference

# Flake inputs
nix flake update     # Update all inputs
```

## Tips

**hardware.nix is a template** — contains local partition UUIDs, excluded via skip-worktree:

```sh
git update-index --skip-worktree hardware.nix      # default
git update-index --no-skip-worktree hardware.nix   # temporarily unskip
```

**Nix superpowers** — any package from Nixpkgs available on-demand without installing:

```sh
nix-shell -p ffmpeg    # use ffmpeg temporarily
nix-shell -p python3   # quick python session
```

**High idle power draw?** NVIDIA might be misbehaving. Check `sudo powertop`.
