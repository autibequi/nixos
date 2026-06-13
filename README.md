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
  hardware/          # asus.nix, nvidia.nix, gpu-toggle.nix, ddc.nix
  services/          # ai.nix, lmstudio.nix, steam.nix, virt.nix
  experiments/       # Optional / on-demand modules (podman, flatpak, dms, whisper-ptt)

stow/
  .config/           # Dotfiles: hypr/, waybar/, zsh/, alacritty/, … (symlinked into ~ via `just stow`)
  .local/bin/        # CLIs: hypr-*, gpu-profile, caffeine-toggle, …
  assets/            # Wallpapers, icons
```

## Flake Inputs

- **nixpkgs**: NixOS 26.05 (stable)
- **nixpkgs-unstable**: unstable channel (available as `unstable` in modules)
- **nixos-hardware**: ASUS Zephyrus GA402X hardware support
- **chaotic**: CachyOS kernel (nyx)
- **claude-code**: claude-code-nix overlay (última versão upstream)
- **dms**: DankMaterialShell (NixOS module)
- **hyprlandFlake**: Hyprland upstream (última versão)
- **llm-agents**: AI coding agents (numtide)

## Commands

```sh
# Build and test (temporary, no commit)
nh os test .

# Apply permanently
nh os switch .

# Deploy dotfiles (stow/ → ~)
just restow
```

## Tips

**Unstable packages** are available in all modules via `specialArgs`:
```nix
environment.systemPackages = [ unstable.some-package ];
```

**Enable/disable features** in `configuration.nix` by commenting/uncommenting imports.

**High idle power draw?** NVIDIA might be misbehaving. Check `sudo powertop`.
