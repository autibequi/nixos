# NixOS — ASUS Zephyrus G14

Flake-based NixOS configuration for an ASUS Zephyrus G14 (AMD Ryzen + NVIDIA RTX 4060 mobile).
Orchestrated by **bardiel** (separate repo).

## Structure

```
flake.nix            # Flake inputs + output nixosConfigurations.nomad
configuration.nix    # fileSystems + registry de imports (liga/desliga pastas e experiments)
Justfile             # switch / update / stow / restow

modules/
  boot/        bootloader · kernel · plymouth · hibernate
  hardware/    base (firmware/amd) · asus · nvidia · audio · bluetooth · logiops · [ddc]
  system/      base · nix · locale · users · networking · performance · services · shell · fonts · programs · packages
  desktop/     hyprland/ · greetd
  services/    ai · lmstudio · obsidian-sync · steam · virt · [ramsync]
  apps/        work (toolchain Estratégia)
  experiments/ podman · flatpak · [dms · whisper-ptt]

stow/          # Dotfiles deployados em ~ via `just restow`
  .config/     # hypr, waybar, quickshell, alacritty, zsh, …
  assets/      # wallpapers, lockscreen, ícones
  _attic/      # configs arquivadas (não deployadas)
```

Cada pasta em `modules/` tem um `default.nix` que importa seus módulos ativos.
Os módulos entre `[colchetes]` estão comentados (opt-in) no `default.nix` da pasta —
para ativar, descomente lá. Experiments são ligados/desligados em `configuration.nix`.

## Flake Inputs

- **nixpkgs**: NixOS 26.05 (stable)
- **nixpkgs-unstable**: unstable channel (disponível como `unstable` nos módulos)
- **nixos-hardware**: ASUS Zephyrus GA402X hardware support
- **chaotic**: CachyOS kernel (nyx)
- **claude-code**: claude-code-nix overlay (última versão upstream)
- **dms**: DankMaterialShell (NixOS module)
- **hyprlandFlake**: Hyprland upstream (última versão)
- **llm-agents**: AI coding agents (numtide)

## Commands

```sh
just switch    # nh os switch . — aplica permanentemente
just update    # nh os switch --update . — atualiza flake e aplica
just restow    # redeploya os dotfiles (stow/ → ~)

# Build temporário (não persiste no boot):
nh os test .
```

## Tips

**Pacotes unstable** estão disponíveis em todos os módulos via `specialArgs`:
```nix
environment.systemPackages = [ unstable.some-package ];
```

**Ligar/desligar feature**: edite o `default.nix` da pasta correspondente
(ou o bloco de experiments em `configuration.nix`).

**Idle power draw alto?** A NVIDIA pode estar se comportando mal. Veja `sudo powertop`.
