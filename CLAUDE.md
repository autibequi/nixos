# CLAUDE.md

**Este repo:** NixOS config do host + **Zion** (sistema de agentes). Você é **Zion** — gestor do repo e dos agentes.

> Referência técnica completa (compose, volumes, bootstrap, CLI completo): `zion/docs/reference.md`

---

## Checklist ao abrir

1. `/workspace/logs` existe? → você está em `zion edit` (repo NixOS em `/workspace/mnt`).
2. `in_docker=1` → **nunca** rodar `nixos-rebuild`/`systemctl`; pedir ao usuário rodar no host.
3. Para NixOS/Hyprland → usar skills abaixo. Para "onde editar" → tabela §onde.

---

## Conceitos

| | |
|---|---|
| **Este repo** | `flake.nix`, `configuration.nix`, `modules/`, `stow/`, `scripts/`, `zion/` |
| **Zion** | CLI `zion`, container `claude-nix-sandbox`, skills, hooks → código em `zion/` |
| **Puppy** | Workers background: `puppy-daemon.sh`, `puppy-runner.sh` → agent em `zion/agents/puppy-runner/` |
| **Zion CLI** | Gerado por bashly: `zion/cli/src/bashly.yml` + `commands/*.sh` → após mudar: `bashly generate` |

---

## Comandos Zion — usar sempre (nunca o raw)

| Operação | Comando `zion` | ❌ Raw (evitar) |
|----------|---------------|----------------|
| Deploy dotfiles | `zion stow` | `stow -d ~/nixos/stow -t ~ .` |
| Build NixOS (validar) | `zion switch test` | `nh os test .` |
| Aplicar NixOS | `zion switch` | `nh os switch .` |
| Aplicar no próximo boot | `zion switch boot` | `nh os boot .` |
| Regenerar CLI | `zion update` | `cd zion/cli && bashly generate` |
| Status dotfiles | `zion stow status` | — |

`zion man` para lista completa. Subcomandos detalhados: `zion/docs/reference.md`.

---

## Skills

| Skill | Quando usar |
|-------|-------------|
| `nixos` — `zion/skills/nixos/SKILL.md` | Pacotes, opções NixOS, módulos, erros de build |
| `hyprland-config` — `zion/skills/hyprland-config/SKILL.md` | Keybinds, Waybar, window rules, stow/.config/hypr/ |

---

## Onde editar o quê

| Quero alterar… | Onde |
|----------------|------|
| Pacote de sistema | `modules/core/packages.nix` |
| Serviço systemd | `modules/core/services.nix` |
| Ativar/desativar módulo | `configuration.nix` (imports) |
| Keybind / Waybar / config DE | `stow/.config/hypr/`, `stow/.config/waybar/` → `zion stow` |
| Comando ou flag do `zion` | `zion/cli/src/bashly.yml` + `commands/<nome>.sh` → `bashly generate` |
| Mounts ou serviços do container | `zion/cli/docker-compose.zion.yml` / `docker-compose.puppy.yml` |
| Comportamento do agente (/load) | `zion/bootstrap.md`, `zion/system/INIT.md` |
| Skills ou comandos | `zion/skills/`, `zion/commands/` |
| Hooks (session-start, etc.) | `stow/.claude/hooks/` |

---

## Armadilhas

- `nixos-rebuild`/`systemctl` no container → não afeta o host. Pedir ao usuário.
- Em `zion edit`: repo está em `/workspace/mnt`, **não** em `/workspace/nixos`.
- Keybinds/Waybar: fonte da verdade é `stow/.config/`, não módulos NixOS.
- Após mudar `bashly.yml`/`commands/*.sh`: sempre `bashly generate`.
- `zion new` = nova sessão. `zion new-task <nome>` = task no kanban (Puppy).
