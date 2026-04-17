# CLAUDE.md — NixOS host config

**Este repo:** NixOS config do ASUS Zephyrus G14. Sem sub-projetos — só a config do sistema.
Orquestração de containers e agentes: **bardiel** (repo separado em `/workspace/bardiel/`).

---

## Checklist ao abrir

1. `host_attached=1`? → `/workspace/host/` editável.
2. `in_docker=1` → **nunca** rodar `nixos-rebuild`/`systemctl` diretamente; pedir ao usuário rodar no host.
3. Para NixOS/Hyprland → usar a skill `linux` (auto-ativa).

---

## Onde editar o quê

| Quero alterar… | Onde |
|----------------|------|
| Pacote de sistema | `modules/core/packages.nix` |
| Programa com opções | `modules/core/programs.nix` |
| Serviço systemd | `modules/core/services.nix` |
| Shell / aliases / env | `modules/core/shell.nix` |
| Fontes | `modules/core/fonts.nix` |
| Kernel / sysctl | `modules/core/kernel.nix` |
| Nix settings | `modules/core/nix.nix` |
| Hibernate | `modules/core/hibernate.nix` |
| Hyprland compositor | `modules/core/hyprland.nix` |
| NVIDIA | `modules/hardware/nvidia.nix` |
| ASUS hardware | `modules/hardware/asus.nix` |
| Bluetooth | `modules/core/bluetooth.nix` |
| Steam / gaming | `modules/services/steam.nix` |
| AI tools | `modules/services/ai.nix` |
| LM Studio | `modules/services/lmstudio.nix` |
| Virtualização | `modules/services/virt.nix` |
| Login greeter | `modules/core/greetd.nix` |
| Boot splash | `modules/core/plymouth.nix` |
| Logitech mouse | `modules/core/logiops.nix` |
| Work tools | `modules/core/work.nix` |
| Ativar/desativar módulo | `configuration.nix` (imports) |
| **Keybinds / windowrules / Waybar** | `stow/.config/hypr/` (via bardiel stow) |

**Pacotes unstable:** usar `unstable.<name>` — disponível via `specialArgs` em todos os módulos.

---

## Comandos

| Operação | Comando |
|----------|---------|
| Testar build (temporário) | `nh os test .` |
| Aplicar permanentemente | `nh os switch .` |
| Deploy dotfiles | `just restow` ou `bardiel os stow` |

---

## Armadilhas

- `nixos-rebuild`/`systemctl` no container → não afeta o host. Pedir ao usuário.
- Keybinds/Waybar: fonte da verdade é `stow/.config/hypr/`, não módulos NixOS.
- `stow/` neste repo contém apenas `assets/` (wallpapers, ícones). Dotfiles (.config/zsh, .config/hypr, etc.) estão em `/workspace/bardiel/stow/`.
