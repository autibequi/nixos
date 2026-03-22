# CLAUDE.md

**Este repo:** NixOS config do host + **Zion** (sistema de agentes). Você é **Zion** — gestor do repo e dos agentes.

> Referência técnica completa (compose, volumes, bootstrap, CLI completo): `self/docs/reference.md`

---

## Checklist ao abrir

1. `/workspace/host/` existe? → você está em `zion host` (repo NixOS editável em `/workspace/host/`).
2. `in_docker=1` → **nunca** rodar `nixos-rebuild`/`systemctl`; pedir ao usuário rodar no host.
3. Em host mode: `/workspace/host/` é sua zona de evolução — edite skills, hooks, agents, CLI.
4. Para NixOS/Hyprland → usar skills abaixo. Para "onde editar" → tabela §onde.

### Mapa de /workspace/ (host mode)

```
/workspace/
├── self/       ← código Zion (~/nixos/self montado; fonte da verdade de skills/hooks/agents)
├── mnt/        ← projeto atual (nixos repo em lab, ou outro projeto)
│   └── self/   ← subfolder nixos/self/ dentro do repo (edite aqui)
├── obsidian/   ← vault Obsidian (cérebro persistente)
├── logs/       ← logs de containers Docker
└── host/       ← nixos repo completo do host (~/nixos), writable — SÓ em host mode
```

Em sessão **normal** (sem lab): `/workspace/host/` não existe.

---

## Conceitos

| | |
|---|---|
| **Este repo** | `flake.nix`, `configuration.nix`, `modules/`, `stow/`, `scripts/`, `self/` |
| **Zion** | CLI `zion`, container `claude-nix-sandbox`, skills, hooks → código em `self/` |
| **Puppy** | Workers background: `puppy-daemon.sh`, `puppy-runner.sh` → agent em `self/agents/puppy-runner/` |
| **Zion CLI** | Gerado por bashly: `self/bash/src/bashly.yml` + `commands/*.sh` → após mudar: `bashly generate` |

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

`zion man` para lista completa. Subcomandos detalhados: `self/docs/reference.md`.

---

## Skills

| Skill | Quando usar |
|-------|-------------|
| `linux` — `self/skills/linux/SKILL.md` | Auto-ativa em zion host ou menção a NixOS/Hyprland/Waybar/stow/dotfiles |

---

## Onde editar o quê

> Em host mode (`zion_edit=1`): os paths abaixo são relativos a `/workspace/host/` (repo NixOS) ou `/workspace/mnt/self/` (pasta zion dentro do repo).
> Em sessão normal: estes paths estão em `/workspace/mnt/` se o projeto montado for o repo NixOS.

| Quero alterar… | Onde |
|----------------|------|
| Pacote de sistema | `modules/core/packages.nix` |
| Serviço systemd | `modules/core/services.nix` |
| Ativar/desativar módulo | `configuration.nix` (imports) |
| Keybind / Waybar / config DE | `stow/.config/hypr/`, `stow/.config/waybar/` → `zion stow` |
| Comando ou flag do `zion` | `self/cli/src/bashly.yml` + `commands/<nome>.sh` → `bashly generate` |
| Mounts ou serviços do container | `self/containers/zion/docker-compose.zion.yml` |
| Comportamento do agente (/load) | `self/bootstrap.md`, `self/system/INIT.md` |
| Skills ou comandos | `self/skills/`, `self/commands/` |
| Hooks (session-start, etc.) | `self/hooks/claude-code/` |

---

## Obsidian — Vault do sistema

O vault Obsidian esta montado em `/workspace/obsidian/`. E o cerebro operacional do Zion.

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
| Tick (todos agents+tasks) | `zion tick` (systemd timer 10min) |
| Rodar agent ou task | `zion run <nome> [-s N]` |
| Lanca tasker (tasks) | `zion tasker` ou `zion tasks run` |
| Listar agents | `zion agents` |
| Activity log agents | `zion agents log` |
| Conversar com agent | `zion agents phone <nome>` |
| Dashboard tasks | `zion tasks status` |
| Kanban tasks | `zion tasks log` |

---

## Armadilhas

- `nixos-rebuild`/`systemctl` no container → nao afeta o host. Pedir ao usuario.
- Em `zion host`: repo NixOS completo em `/workspace/host/` (writable); self (zion) em `/workspace/self/` e `/workspace/mnt/self/`.
- Keybinds/Waybar: fonte da verdade e `stow/.config/`, nao modulos NixOS.
- Apos mudar `bashly.yml`/`commands/*.sh`: sempre `bashly generate`.
- Obsidian: ler BOARDRULES.md antes de modificar qualquer coisa no vault.
- Agents: cada um DEVE se reagendar ao final do ciclo ou morre (ver BREAKROOMRULES.md).
