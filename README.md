# NixOS

Flake-based NixOS configuration for an ASUS Zephyrus G14 (AMD Ryzen + NVIDIA RTX 4060 mobile).

## Structure

```
flake.nix            # Flake inputs and nixosConfigurations.nomad output
configuration.nix    # Module registry (enable/disable features here)
hardware.nix         # Partition UUIDs (local-only, git skip-worktree'd)

modules/
  core/              # Essential modules (kernel, nix, packages, services, shell, fonts, hibernate)
  hyprland.nix       # Hyprland compositor (active DE)
  nvidia.nix         # NVIDIA PRIME offload (AMD iGPU as default)
  asus.nix           # ASUS-specific hardware support
  greetd.nix         # Login greeter
  bluetooth.nix      # Bluetooth
  plymouth.nix       # Boot splash
  steam.nix          # Gaming
  ai.nix             # AI tools (ComfyUI, Stable Diffusion)
  podman.nix         # Containers
  logiops.nix        # Logitech mouse config
  work.nix           # Work-related setup
  virt.nix           # Virtualization
  gnome/             # GNOME DE (disabled)
  cosmic.nix         # COSMIC DE (disabled)
  kde.nix            # KDE DE (disabled)

stow/                # Dotfiles managed with GNU stow (symlinked into ~)
  .config/           # App configs (hypr, waybar, zed, ghostty, rofi, etc.)
```

## Flake Inputs

- **nixpkgs**: NixOS 25.11 (stable)
- **nixpkgs-unstable**: unstable channel (available as `unstable` in modules)
- **chaotic**: CachyOS kernel
- **hyprland**: pinned to v0.54.0
- **nixos-hardware**: ASUS Zephyrus hardware support
- **zen-browser**, **zed**, **isd**, **voxtype**, **nixified-ai**, **antigravity-nix**

## Installation

Get a shell with git and an editor:

```sh
nix-shell -p helix git
```

Extract partition UUIDs from the auto-generated hardware config:

```sh
cat /etc/nixos/hardware-configuration.nix | grep -B 3 "device ="
```

Clone this repo, then set the boot, root, and swap UUIDs in `hardware.nix`.

Apply the configuration:

```sh
sudo nixos-rebuild switch --flake .#nomad
```

Reboot and hope for the best.

## Common Commands

```sh
# Build without switching (test for errors)
sudo nixos-rebuild build --flake .#nomad

# Update all flake inputs
nix --extra-experimental-features 'nix-command flakes' flake update

# Update a single input
nix --extra-experimental-features 'nix-command flakes' flake update nixpkgs

# Apply dotfiles
stow -d ~/projects/nixos/stow -t ~ .
```

## Tips

**hardware.nix is a template** - it contains local partition UUIDs and is excluded from git via skip-worktree:

```sh
# Skip (default)
git update-index --skip-worktree hardware.nix

# Temporarily unskip to update the template
git update-index --no-skip-worktree hardware.nix
```

**High idle power draw?** NVIDIA might be misbehaving. Check `sudo powertop` and enable the suggested tunables.

**SSH key for push/pull:**

```sh
ssh-keygen -t ed25519 -C "your_email@example.com"
```
