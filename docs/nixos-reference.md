# NixOS Reference

## Comandos
```sh
sudo nixos-rebuild switch --flake .#nomad   # Apply config
sudo nixos-rebuild build --flake .#nomad    # Test build
nix --extra-experimental-features 'nix-command flakes' flake update  # Update inputs
stow -d ~/nixos/stow -t ~ .       # Apply dotfiles
```

## Arquitetura
Config flake-based para ASUS Zephyrus G14 (AMD Ryzen + NVIDIA RTX 4060 mobile).
- `flake.nix` — nixpkgs stable + unstable, Hyprland v0.54.0
- `configuration.nix` — module registry (comment/uncomment to enable/disable)
- `hardware.nix` — UUIDs (skip-worktree, template only)
- `modules/core/` — kernel, nix settings, packages, services, shell, fonts, hibernate
- `modules/` — nvidia, asus, bluetooth, steam, ai, podman, work, virt, hyprland
- NVIDIA: PRIME offload (AMD iGPU default)
