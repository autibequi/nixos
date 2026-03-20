# Zion — Referência Técnica Completa

> Lido sob demanda. Para o cheat-sheet rápido: `/workspace/mnt/CLAUDE.md`.

---

## CLI — Todos os subcomandos

| Comando | O que faz |
|---------|-----------|
| **`zion`** (sem subcomando) | **New** — abre uma nova sessão (equivalente a `zion new`). |
| **`zion continue`** | Continua a última sessão (opencode, claude, cursor). Sem lista, sem prompt. |
| **`zion new`** | Nova sessão no container. Exige `--engine` (ou `engine=` em `~/.zion`). Aliases: `run`, `r`, `open`, `opencode`, `code`. |
| **`zion resume`** | Mostra lista de sessões, pergunta UUID ou Enter para última, depois conecta. `--resume=UUID` pula a lista. |
| **`zion new-task <nome>`** | Cria task + card no kanban (Puppy). |
| **`zion edit`** | Sessão com `~/nixos` em `/workspace/mnt` + `/workspace/logs`. Project name fixo `zion-projects`. |
| **`zion leech [dir]`** | Sessão efêmera em qualquer pasta. Auto-detecta nixos repo → monta logs. Alias: `l`. |
| **`zion shell`** | Bash no container com o projeto montado. |
| **`zion tasks tick`** | Executa cards vencidos do kanban (local, sem container). |
| **`zion tasks tick --dry-run`** | Lista o que seria executado sem rodar. |
| **`zion tasks run <nome>`** | Roda 1 card específico pelo nome. |
| **`zion tasks run <nome> -t N`** | Roda com max-turns override. |
| **`zion tasks list`** | Lista TODO/DOING/DONE. |
| **`zion tasks new <nome>`** | Cria novo card de task. |
| **`zion tasks status`** | Log das últimas execuções. |
| **`zion claude-usage`** | Estatísticas de uso Claude. `--waybar` = JSON para usage bar; `--refresh` = ignora cache. |

---

## Modo Headless

Quando `HEADLESS=1` (tasks via task-runner.sh):
1. **Autonomia total** — não esperar input, não fazer perguntas.
2. **Maximize progresso** — vá o mais longe possível.
3. **Gestão de tempo** — reserve os últimos ~30s para salvar estado (memoria.md, contexto.md). SIGKILL sem aviso.
4. **Ciclos curtos** — executar → salvar parcial → continuar.
5. **Sem output decorativo** — foco em execução e persistência.

`timeout <seconds>` no frontmatter do card — hard limit (default 1800s).

---

## Paths e modos de sessão

### Variáveis de ambiente no container

| Variável | Significado |
|----------|-------------|
| `CLAUDE_ENV=container` | Você está dentro do container |
| `IS_CONTAINER=1` | Definido pelo bootstrap — nunca rodar nixos-rebuild/systemctl |
| `WS=/workspace` | Raiz do workspace no container |

### Paths disponíveis

| Path | Conteúdo |
|------|----------|
| `/zion` | `zion/` do repo (skills, commands, agents, bootstrap, scripts) |
| `/workspace/mnt` | Projeto montado (CWD típico) |
| `/workspace/obsidian` | Vault Obsidian |
| `/workspace/logs` | Logs do host — **só em `zion edit`** |

### Modos de sessão e mounts

| Modo | `/workspace/mnt` | `/workspace/logs` |
|------|-----------------|-------------------|
| `zion` / `new` / `shell` / `resume` | Projeto do usuário | ❌ |
| **`zion edit`** | `~/nixos` (este repo) | ✅ (journal ro) |
| **`zion leech ~/nixos`** | `~/nixos` (auto-detect) | ✅ (journal ro) |
| **`zion leech <outro-dir>`** | Dir especificado | ❌ |

---

## Como o container é iniciado

- CLI no host (`zion/cli/`) usa Docker Compose: `docker-compose.zion.yml` (sessões interativas).
- Imagem: `claude-nix-sandbox` (build de `zion/cli/Dockerfile.claude`).
- **leech** — sessão efêmera: `sleep infinity` + `exec` do engine.
- **Tasks** rodam direto no host via `systemd zion-tick.timer` → `zion tasks tick`.

### Volumes base (`x-base-volumes`)
- `/zion` ← `zion/` do repo
- `/workspace/obsidian` ← `OBSIDIAN_PATH`
- `/workspace/mnt` ← `CLAUDIO_MOUNT`
- `~/.claude`, `~/.cursor`, skills/commands, hooks do stow, `cursor_config` (volume nomeado)
- `/host/proc/*`, `/host/etc/*` (ro, observabilidade)
- `/workspace/.hive-mind`

Em `zion edit` / `zion leech ~/nixos` (extras):
- `/workspace/mnt` = `~/nixos`
- `/workspace/logs/host/journal` ← `/var/log/journal` (ro)

---

## Bootstrap em cadeia

1. CLI sobe container e executa: `. /zion/scripts/bootstrap.sh; cd /workspace/mnt; exec <engine>`
2. `/zion/scripts/bootstrap.sh`:
   - Cria `/workspace/host` como symlink para o repo NixOS
   - Chama `scripts/bootstrap.sh` do repo NixOS
3. `scripts/bootstrap.sh`:
   - Sync de `stow/.claude/*` → `~/.claude/`
   - Carrega `scripts/bootstrap/modules.sh` → define `IS_CONTAINER`, `WS`, módulos do dashboard

---

## Mapa do repositório

```
.
├── CLAUDE.md              ← Cheat-sheet do agente
├── flake.nix              ← Inputs (nixpkgs 25.11, home-manager, etc.)
├── configuration.nix      ← Registry de módulos (imports)
├── hardware.nix           ← UUIDs de partição (skip-worktree)
├── modules/
│   ├── core/              ← packages, services, programs, fonts, shell, kernel
│   ├── hyprland.nix       ← Compositor ativo
│   ├── nvidia.nix         ← NVIDIA PRIME
│   ├── asus.nix           ← ASUS Zephyrus
│   └── agents/            ← Agent options (agent-container)
├── stow/
│   ├── .config/           ← hypr, waybar, zed, ghostty, rofi, zsh, etc.
│   └── .claude/           ← Hooks, scripts, agents (Claude host/container)
├── scripts/               ← bootstrap.sh, task-daemon.sh, task-runner.sh, api-usage.sh, etc.
└── zion/
    ├── cli/               ← CLI zion (bashly.yml + commands/*.sh + docker-compose)
    ├── scripts/           ← Bootstrap e scripts do container
    ├── system/            ← INIT.md, SOUL.md, SELF.md, DIRETRIZES.md
    ├── commands/          ← Comandos do agente
    ├── skills/            ← Skills (nixos, hyprland-config, monolito, etc.)
    ├── agents/            ← Agentes (orquestrador, etc.)
    ├── personas/          ← Avatars e personas
    ├── hooks/             ← Hooks claude-code
    └── docs/              ← Esta documentação de referência
```

---

## Se algo falhar

| Situação | O que fazer |
|----------|-------------|
| Build NixOS falha | `nh os test .` no host; skill **nixos**; tabela de módulos no CLAUDE.md |
| Container não sobe | Ver `zion/cli/docker-compose.zion.yml`; seção de volumes acima |
| Keybind/Waybar não aplica | Skill **hyprland-config**; verificar `stow/.config/hypr/`; `hyprls lint` |
| Comando `zion` desatualizado | `cd zion/cli && bashly generate` (ou `zion update` no host) |

---

## Nomes de projeto no compose

- Sessões interativas: `zion-<slug>` ou `zion-projects` (edit/leech nixos)
- Config em `~/.zion` (não `~/.claudio`)
