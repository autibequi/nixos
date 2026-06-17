# CLAUDE.md — NixOS host config

**Este repo:** NixOS config do ASUS Zephyrus G14 + dotfiles (em `stow/`). Config do sistema + dotfiles do usuário.

---

## Checklist ao abrir

1. `host_attached=1`? → `/workspace/host/` editável.
2. `in_docker=1` → **nunca** rodar `nixos-rebuild`/`nh os switch`/`systemctl` no container; pedir ao usuário rodar no host.
3. Flake só enxerga arquivo **git-tracked** → após criar arquivo novo, `git add` antes do `nh os test/switch`.

---

## Estrutura

`configuration.nix` define os `fileSystems` e importa as **pastas** de `modules/`.
Cada pasta tem um `default.nix` que importa seus módulos ativos.

```
modules/
  boot/        bootloader · kernel · plymouth · hibernate
  hardware/    base · asus · nvidia · audio · bluetooth · logiops · [gpu-toggle · ddc]
  system/      base · nix · locale · users · networking · performance · services · shell · fonts · programs · packages
  desktop/     hyprland/ · greetd
  services/    ai · lmstudio · obsidian-sync · steam · virt · [ramsync]
  apps/        work
  experiments/ podman · flatpak · [dms · whisper-ptt]
```

## Onde editar o quê

| Quero alterar… | Onde |
|----------------|------|
| Pacote de sistema geral | `modules/system/packages.nix` |
| Programa com opções (direnv, starship, waydroid) | `modules/system/programs.nix` |
| Serviço systemd de base (printing, upower, udisks) | `modules/system/services.nix` |
| Tuning de performance (oomd, journald, slices, limites) | `modules/system/performance.nix` |
| Shell / toolchain CLI | `modules/system/shell.nix` |
| Variáveis de ambiente / tmpfs / stateVersion | `modules/system/base.nix` |
| Locale / teclado / timezone | `modules/system/locale.nix` |
| Usuários e grupos | `modules/system/users.nix` |
| Rede / SSH / Tailscale / firewall | `modules/system/networking.nix` |
| Fontes | `modules/system/fonts.nix` |
| Nix settings / GC / caches / auto-upgrade | `modules/system/nix.nix` |
| Kernel / sysctl / scheduler (scx) | `modules/boot/kernel.nix` |
| Bootloader (Limine) | `modules/boot/bootloader.nix` |
| Boot splash (Plymouth) | `modules/boot/plymouth.nix` |
| Hibernate / suspend | `modules/boot/hibernate.nix` |
| Áudio (PipeWire) | `modules/hardware/audio.nix` |
| Bluetooth | `modules/hardware/bluetooth.nix` |
| NVIDIA | `modules/hardware/nvidia.nix` |
| Firmware / amdgpu / microcode | `modules/hardware/base.nix` |
| ASUS hardware (asusd/supergfxd) | `modules/hardware/asus.nix` |
| Mouse Logitech | `modules/hardware/logiops.nix` |
| Hyprland (pacotes/portals/sessões) | `modules/desktop/hyprland/` |
| Login greeter (tuigreet) | `modules/desktop/greetd.nix` |
| Steam / gaming | `modules/services/steam.nix` |
| AI tools | `modules/services/ai.nix` |
| LM Studio | `modules/services/lmstudio.nix` |
| Virtualização (QEMU/KVM) | `modules/services/virt.nix` |
| Obsidian sync headless | `modules/services/obsidian-sync.nix` |
| Work tools (Estratégia) | `modules/apps/work.nix` |
| Container engine (podman) | `modules/experiments/podman.nix` |
| Ativar/desativar módulo | `modules/<pasta>/default.nix` |
| Ativar/desativar experiment | `configuration.nix` (bloco imports) |
| **Keybinds / windowrules / Hyprland Lua** | `stow/.config/hypr/` (deploy via `just restow`) |

**Pacotes unstable:** usar `unstable.<name>` — disponível via `specialArgs` em todos os módulos.

---

## Comandos

| Operação | Comando |
|----------|---------|
| Testar build (temporário) | `nh os test .` |
| Aplicar permanentemente | `just switch` (= `nh os switch .`) |
| Atualizar flake e aplicar | `just update` |
| Deploy dotfiles | `just restow` |

---

## Armadilhas

- `nixos-rebuild`/`systemctl` no container → não afeta o host. Pedir ao usuário.
- Flake ignora arquivo untracked → `git add` antes de testar config com arquivo novo.
- Keybinds/Hyprland: fonte da verdade é `stow/.config/hypr/` (config Lua), não os módulos NixOS.
- Podman roda **rootless**: o socket de usuário é declarado à mão em `experiments/podman.nix`
  (`systemd.user.*`) porque o nixpkgs não tem `rootlessSocket.enable`. Não é redundante.
- `stow/` contém os dotfiles: `.config/` (hypr, waybar, quickshell, alacritty, zsh, …) e
  `assets/` (wallpapers, ícones). Os CLIs locais ficam em `stow/.local/bin/` mas **não são
  versionados** (estão no `.gitignore`). Deploy via `just restow`.
