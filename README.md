# NixOS — ASUS Zephyrus G14

Flake-based NixOS configuration for an ASUS Zephyrus G14 (AMD Ryzen + NVIDIA RTX 4060 mobile).
Orchestrated by **bardiel** (separate repo).

## Structure

```
flake.nix            # Flake inputs and nixosConfigurations.nomad output
configuration.nix    # Module registry (enable/disable features here)
Justfile             # restow recipe

modules/
  core/              # Essential modules (kernel, nix, shell, packages, services, fonts…)
  hardware/          # asus.nix, nvidia.nix
  services/          # ai.nix, lmstudio.nix, steam.nix, virt.nix, containers.nix…
  experiments/       # Optional / disabled modules (podman, cosmic, kde, whisper-ptt…)

stow/
  assets/            # Wallpapers, icons (symlinked into ~ via bardiel plug stow)
```

## Flake Inputs

- **nixpkgs**: NixOS 25.11 (stable)
- **nixpkgs-unstable**: unstable channel (available as `unstable` in modules)
- **chaotic**: CachyOS kernel
- **nixos-hardware**: ASUS Zephyrus hardware support
- **home-manager**: release-25.11
- **claude-code**: claude-code-nix overlay
- **nix-index-database**: nix-index DB

## Commands

```sh
# Build and test (temporary, no commit)
nh os test .

# Apply permanently
nh os switch .

# Deploy dotfiles (bardiel stow/ → ~)
just restow
# or via bardiel:
bardiel os stow
```

## Tips

**Unstable packages** are available in all modules via `specialArgs`:
```nix
environment.systemPackages = [ unstable.some-package ];
```

**Enable/disable features** in `configuration.nix` by commenting/uncommenting imports.

**High idle power draw?** NVIDIA might be misbehaving. Check `sudo powertop`.
