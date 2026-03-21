---
name: linux
description: "Auto-ativar quando: zion_edit=1 (zion lab), ou usuário menciona NixOS, Hyprland, Waybar, dotfiles, stow, nix, módulos, pacotes do sistema, keybinds, window rules ou configuração do compositor."
---

# linux — Sistema Linux (NixOS + Hyprland + dotfiles)

Skill unificada para tudo que envolve o sistema Linux: pacotes NixOS, módulos, opções, dotfiles, Hyprland, Waybar, stow.

## Passo 0 — Plan Mode Obrigatório

Chamar `EnterPlanMode` imediatamente antes de qualquer ação.
Sair apenas após aprovação explícita do dev.
Exceção: se invocado dentro de fluxo Orquestrador já aprovado, pular.

---

## Workflow NixOS

```
User requests a change
  -> Search package/option (MCP-NixOS)
  -> Identify correct module to edit
  -> Edit module
  -> nh os test .
  -> Pass? -> Done
  -> Fail? -> Classify error -> Fix -> nh os test . (loop, max 3 auto-retries)
```

## Step 1: Search com MCP-NixOS

```
mcp__nixos__nix(action: "search", type: "packages", query: "firefox")
mcp__nixos__nix(action: "search", type: "options", query: "services.openssh")
mcp__nixos__nix(action: "info", type: "packages", query: "nixpkgs#firefox")
mcp__nixos__nix(action: "info", type: "options", query: "services.openssh.enable")
mcp__nixos__nix(action: "search", type: "home-manager-options", query: "programs.git")
```

Se MCP indisponível: `nh search <query>`.

## Step 2: Módulo correto

| Mudança | Arquivo |
|---------|---------|
| Pacote de sistema | `modules/core/packages.nix` |
| Programa com opções | `modules/core/programs.nix` |
| Serviço systemd | `modules/core/services.nix` |
| Fonte | `modules/core/fonts.nix` |
| Shell alias / env / starship | `modules/core/shell.nix` |
| Kernel / sysctl | `modules/core/kernel.nix` |
| Nix settings | `modules/core/nix.nix` |
| Hibernate | `modules/core/hibernate.nix` |
| NVIDIA | `modules/nvidia.nix` |
| ASUS hardware | `modules/asus.nix` |
| Bluetooth | `modules/bluetooth.nix` |
| Hyprland compositor | `modules/hyprland.nix` |
| Steam / gaming | `modules/steam.nix` |
| AI tools | `modules/ai.nix` |
| Containers (podman) | `modules/podman.nix` |
| Virtualização | `modules/virt.nix` |
| Work tools | `modules/work.nix` |
| Login greeter | `modules/greetd.nix` |
| Boot splash | `modules/plymouth.nix` |
| Logitech mouse | `modules/logiops.nix` |
| **Keybinds / windowrules / Waybar** | `stow/.config/hypr/` → `zion stow` |

**Pacotes unstable:** usar `unstable.pkgs.<name>` — disponível em todos os módulos via `specialArgs`.

## Step 3: Build e Test

```bash
nh os test .
```

Ativa temporariamente (não persiste). **Nunca rodar `nh os switch .`** sem o user pedir explicitamente.

## Step 4: Error Handling

### Auto-fix (max 3 tentativas):

| Erro | Fix |
|------|-----|
| `undefined variable 'pkgName'` | Nome errado — buscar no MCP |
| `attribute 'x' missing` | Path errado — verificar com MCP info |
| `syntax error` | Nix syntax — corrigir |
| `option 'x' does not exist` | Opção errada — buscar MCP |
| `duplicate definition` | Remover duplicata |
| `not available on hostPlatform` | Remover ou buscar alternativa |

### Pedir confirmação:

| Erro | Ação |
|------|------|
| `collision between` | Mostrar ambos, perguntar qual manter |
| `infinite recursion` | Explicar ciclo, propor fix |
| `assertion failed` | Explicar condição, propor fix |
| Erro desconhecido | Mostrar completo, pedir orientação |

---

## Hyprland

Dois layers distintos:

```
Layer 1: NixOS Module (modules/hyprland.nix)
  ↓ pacotes, UWSM, serviços systemd
Layer 2: Dotfile Configs (stow/.config/hypr/*.conf)
  ↓ keybinds, windowrules, waybar, animações
```

**Regra de ouro:**
- Instalar/habilitar Hyprland, plugins → `modules/hyprland.nix` → `nh os test .`
- Keybinds, windowrules, Waybar, animações → `stow/.config/hypr/` → `zion stow` → `hyprctl reload`

Nunca editar `~/.config/hypr/` diretamente — é symlink. Fonte: `stow/.config/hypr/`.

### Arquivos de dotfile

| Arquivo | Conteúdo |
|---------|----------|
| `hyprland.conf` | Config principal |
| `hypridle.conf` | Idle / sleep |
| `hyprlock.conf` | Lock screen |
| `workspace.conf` | Layout de workspaces |
| `application.conf` | Window rules por app |
| `windowrules.conf` | Window rules gerais |
| `systemtools.conf` | Atalhos de sistema |

### Ciclo dotfiles

```bash
# 1. Editar stow/.config/hypr/
# 2. Deploy
zion stow
# 3. Recarregar
hyprctl reload
```

### Troubleshooting

| Problema | Diagnóstico |
|----------|-------------|
| Sessão não aparece no login | `systemctl status uwsm` |
| Crash imediato | `journalctl -xe` + `hyprls lint stow/.config/hypr/hyprland.conf` |
| Waybar/hypridle não sobem | `journalctl -u waybar -n 50` |
| Tela preta | Verificar `source =` no hyprland.conf |

---

## Quick Reference

| Task | Comando |
|------|---------|
| Test build | `nh os test .` |
| Aplicar permanentemente | `nh os switch .` (só se user pedir) |
| Buscar pacotes | `mcp__nixos__nix search packages <query>` |
| Buscar opções | `mcp__nixos__nix search options <query>` |
| Deploy dotfiles | `zion stow` |
| Reload Hyprland | `hyprctl reload` |
| Logs Hyprland | `journalctl -xe --grep=hypr` |
