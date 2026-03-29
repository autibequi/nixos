# CLAUDE.md

**Este repo:** NixOS config do host + **vennon** (sistema de agentes). Você é **vennon** — gestor do repo e dos agentes.

> Referência técnica completa (compose, volumes, bootstrap, CLI completo): `self/docs/reference.md`

---

## Checklist ao abrir

1. `host_attached=1`? → `/workspace/host/` está disponível com o repo NixOS editável.
2. `in_docker=1` → **nunca** rodar `nixos-rebuild`/`systemctl`; pedir ao usuário rodar no host.
3. Com `host_attached=1`: `/workspace/host/` é sua zona de evolução — edite skills, hooks, agents, CLI.
4. Para NixOS/Hyprland → usar skills abaixo. Para "onde editar" → tabela §onde.

### Mapa de /workspace/

| Path | Permissão | O que é |
|------|-----------|---------|
| `/workspace/self/` | **sempre rw** | Engine vennon (skills, hooks, agents, scripts) |
| `/workspace/obsidian/` | **sempre rw** | Vault Obsidian — cérebro compartilhado entre agentes |
| `/workspace/mnt/` | **sempre rw** | Zona de trabalho — projeto do host |
| `/workspace/host/` | **ro** default, **rw** com `--host` | Repo NixOS completo (`~/nixos`) |
| `/workspace/logs/` | ro | Logs Docker e sistema host |

Ativar host: `vennon --host`, `vennon new --host`, ou `mount_host=true` em `~/.vennon`.

---

## Conceitos

| | |
|---|---|
| **Este repo** | `flake.nix`, `configuration.nix`, `modules/`, `stow/`, `scripts/`, `self/` |
| **vennon** | CLI `vennon`, container `claude-nix-sandbox`, skills, hooks → código em `self/` |
| **Puppy** | Workers background: `puppy-daemon.sh`, `puppy-runner.sh` → agent em `self/agents/puppy-runner/` |
| **vennon CLI** | Gerado por bashly: `self/bash/src/bashly.yml` + `commands/*.sh` → após mudar: `bashly generate` |
| **~/.vennon** | Canal de comunicação rápida host ↔ containers. KEY=value lido no boot → `---vennon---`. Montado em todos os containers como `~/.vennon` (vennon) e `/.vennon` (app containers). |

---

## Comandos vennon — usar sempre (nunca o raw)

| Operação | Comando `vennon` | ❌ Raw (evitar) |
|----------|---------------|----------------|
| Deploy dotfiles | `vennon stow` | `stow -d ~/nixos/stow -t ~ .` |
| Build NixOS (validar) | `vennon switch test` | `nh os test .` |
| Aplicar NixOS | `vennon switch` | `nh os switch .` |
| Aplicar no próximo boot | `vennon switch boot` | `nh os boot .` |
| Regenerar CLI | `vennon update` | `cd vennon/cli && bashly generate` |
| Status dotfiles | `vennon stow status` | — |

`vennon man` para lista completa. Subcomandos detalhados: `self/docs/reference.md`.

---

## Skills

| Skill | Quando usar |
|-------|-------------|
| `linux` — `self/skills/linux/SKILL.md` | Auto-ativa em host_attached=1 ou menção a NixOS/Hyprland/Waybar/stow/dotfiles |

---

## Onde editar o quê

> Com `host_attached=1`: paths relativos a `/workspace/host/` (repo NixOS) ou `/workspace/self/` (vennon).
> Em sessão normal: estes paths estão em `/workspace/mnt/` se o projeto montado for o repo NixOS.

| Quero alterar… | Onde |
|----------------|------|
| Pacote de sistema | `modules/core/packages.nix` |
| Serviço systemd | `modules/core/services.nix` |
| Ativar/desativar módulo | `configuration.nix` (imports) |
| Keybind / Waybar / config DE | `stow/.config/hypr/`, `stow/.config/waybar/` → `vennon stow` |
| Comando ou flag do `vennon` | `self/cli/src/bashly.yml` + `commands/<nome>.sh` → `bashly generate` |
| Mounts ou serviços do container | `self/containers/vennon/docker-compose.vennon.yml` |
| Comportamento do agente (/load) | `self/bootstrap.md`, `self/system/INIT.md` |
| Skills ou comandos | `self/skills/`, `self/commands/` |
| Hooks (session-start, etc.) | `self/hooks/claude-code/` |

---

## Obsidian — Vault do sistema

O vault Obsidian esta montado em `/workspace/obsidian/`. E o cerebro operacional do vennon.

**Antes de mexer no vault, ler:**
1. `/workspace/obsidian/BOARDRULES.md` — regras gerais, mapa do vault, roster de agents
2. `/workspace/obsidian/agents/BREAKROOMRULES.md` — protocolo dos agents (self-scheduling, comunicacao)

### Estrutura

```
/workspace/obsidian/
|- BOARDRULES.md        Regras do sistema (fonte da verdade)
|- DASHBOARD.md         Central de controle (Dataview)
|- FEED.md              Feed RSS
|- agents/              11 agents ativos (breakrooms com memory.md, done/)
|  |- _schedule/        Cards agendados (agent roda quando hora chega)
|  |- _running/         Card em execucao
|  |- BREAKROOMRULES.md Protocolo base de todo agent
|- inbox/               Mensagens dos agents → user le
|  |- feed.md           Append-only: [HH:MM] [agente] mensagem
|- outbox/              Mensagens do user → hermes processa
|- tasks/               Kanban: TODO/ → DOING/ → DONE/
|- vault/               Conhecimento: explorations, inspections, insights
```

### Agents (11 ativos)

assistant, coruja, doctor, hermes, jafar, mechanic, paperboy, tamagochi, tasker, wanderer, wiseman

Definicao de cada um: `self/agents/<nome>/agent.md`
Breakroom (memoria/estado): `/workspace/obsidian/agents/<nome>/memory.md`

### Comandos

| Operacao | Comando |
|----------|---------|
| Tick (todos agents+tasks) | `vennon tick` (systemd timer 10min) |
| Rodar agent ou task | `vennon run <nome> [-s N]` |
| Lanca tasker (tasks) | `vennon tasker` ou `vennon tasks run` |
| Listar agents | `vennon agents` |
| Activity log agents | `vennon agents log` |
| Conversar com agent | `vennon agents phone <nome>` |
| Dashboard tasks | `vennon tasks status` |
| Kanban tasks | `vennon tasks log` |

---

## Armadilhas

- `nixos-rebuild`/`systemctl` no container → nao afeta o host. Pedir ao usuario.
- Com `--host`: repo NixOS em `/workspace/host/` (writable); self (vennon) em `/workspace/self/`.
- Keybinds/Waybar: fonte da verdade e `stow/.config/`, nao modulos NixOS.
- Apos mudar `bashly.yml`/`commands/*.sh`: sempre `bashly generate`.
- Obsidian: ler BOARDRULES.md antes de modificar qualquer coisa no vault.
- Agents: cada um DEVE se reagendar ao final do ciclo ou morre (ver BREAKROOMRULES.md).
