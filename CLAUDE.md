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
| `linux` — `zion/skills/linux/SKILL.md` | Auto-ativa em zion lab ou menção a NixOS/Hyprland/Waybar/stow/dotfiles |

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

## Obsidian — Vault do sistema

O vault Obsidian esta montado em `/workspace/obsidian/`. E o cerebro operacional do Zion.

**Antes de mexer no vault, ler:**
1. `/workspace/obsidian/BOARDRULES.md` — regras gerais, mapa do vault, roster de contractors
2. `/workspace/obsidian/contractors/CONTRACTORS.RULES.md` — protocolo dos contractors (self-scheduling, comunicacao)

### Estrutura

```
/workspace/obsidian/
|- BOARDRULES.md        Regras do sistema (fonte da verdade)
|- DASHBOARD.md         Central de controle (Dataview)
|- FEED.md              Feed RSS
|- contractors/         11 contractors ativos (pastas com memory.md, card.md, done/)
|  |- _schedule/        Cards agendados (contractor roda quando hora chega)
|  |- _running/         Card em execucao
|  |- CONTRACTORS.RULES.md  Protocolo base de todo contractor
|- inbox/               Mensagens dos contractors → user le
|  |- feed.md           Append-only: [HH:MM] [agente] mensagem
|- outbox/              Mensagens do user → hermes processa
|- tasks/               Kanban: TODO/ → DOING/ → DONE/
|- vault/               Conhecimento: explorations, inspections, insights
```

### Contractors (11 ativos)

assistant, coruja, doctor, hermes, jafar, mechanic, paperboy, tamagochi, tasker, wanderer, wiseman

Definicao de cada um: `zion/agents/<nome>/agent.md`
Memoria/estado: `/workspace/obsidian/contractors/<nome>/memory.md`

### Comandos

| Operacao | Comando |
|----------|---------|
| Listar contractors | `zion contractors` |
| Status detalhado | `zion contractors status` |
| Rodar um contractor | `zion contractors run <nome>` |
| Executar cards vencidos | `zion contractors work` |
| Listar tasks | `zion tasks` |
| Criar task | `zion tasks add <titulo>` |
| Executar tasks vencidas | `zion tasks work` |

---

## Armadilhas

- `nixos-rebuild`/`systemctl` no container → nao afeta o host. Pedir ao usuario.
- Em `zion edit`: repo esta em `/workspace/mnt`, **nao** em `/workspace/nixos`.
- Keybinds/Waybar: fonte da verdade e `stow/.config/`, nao modulos NixOS.
- Apos mudar `bashly.yml`/`commands/*.sh`: sempre `bashly generate`.
- Obsidian: ler BOARDRULES.md antes de modificar qualquer coisa no vault.
- Contractors: cada um DEVE se reagendar ao final do ciclo ou morre (ver CONTRACTORS.RULES.md).
