# Leech — Glossario

Nomenclatura do sistema. Referencia rapida para entender os termos usados em skills, hooks e conversas.

## Sistema

| Termo | O que e |
|-------|---------|
| **Leech** | O sistema como um todo — CLI, hooks, skills, agentes, scripts (antes chamado Zion) |
| **leech** | Comando CLI (`~/.local/bin/leech`). Alias: `zion` |
| **~/.leech** | Tokens e env vars bash-sourceable (legado — config migrou pro YAML) |
| **config.yaml** | `~/.config/leech/config.yaml` — config estruturado via Figment (session, runner, agents, paths, system) |

## Agentes e instancias

| Termo | O que e |
|-------|---------|
| **Eu / Claude externo** | Claude sonnet rodando nesta sessao interativa |
| **Mini-Leech** | Claude haiku spawned por mim — efemero, usado como maquete de desenvolvimento |
| **Puppy** | Container persistente que roda o task-daemon em background |
| **Agente** | Claude headless rodando uma task card especifica (hermes, keeper, mechanic...) |

## Convencoes de nome

| Prefixo/Pattern | Significado |
|-----------------|-------------|
| `leech-dk-<service>` | Container Docker de servico (ex: leech-dk-monolito-app) |
| `leech-<slug>` | Sessao Claude ativa (proj_name em paths.rs) |
| `LEECH_*` | Env vars do sistema — Figment mapeia `LEECH_SESSION_ENGINE`, `LEECH_RUNNER_ENV`, etc. para nested config |
| `HOST_ATTACHED` | 1 quando --host ativo (~/nixos rw em /workspace/host). Substitui antigo LEECH_EDIT. |
| `leech-tick` | Systemd timer/service (roda a cada 10min) |

## Paths essenciais

| Path | Conteudo |
|------|---------|
| `leech/self/` | Fonte da verdade — identidade, agents, commands, hooks, personas, scripts, skills, system |
| `leech/bash/` | CLI bash legado (mantido para referência, não é o ativo) |
| `leech/rust/` | CLI Rust ativo — fonte da verdade do leech CLI |
| `leech/docker/` | Docker compose, Dockerfiles, entrypoints |
| `~/.local/bin/leech` | Binario CLI Rust (instalado via `just install`) |
| `~/.leech` | Tokens + env vars legado (bash-sourceable) |
| `~/.config/leech/config.yaml` | Config YAML estruturado (Figment: session, runner, agents, paths, system) |
| `~/.local/share/leech/` | Logs, estado, cache |
| `/tmp/leech-hive-mind` | Socket Docker compartilhado |
| `/tmp/leech-locks/` | Locks de concorrencia de tasks |
| `/workspace/obsidian/` | Vault Obsidian (cerebro operacional) |

## Persistencia

| O que | Vive onde | Morre quando |
|-------|-----------|--------------|
| Source code (hooks, skills, scripts) | `leech/self/` + GitHub | nunca (se commitado) |
| Memorias cross-session | `/home/claude/.claude/projects/*/memory/` | volume Docker deletado |
| Tasks / kanban | `/workspace/obsidian/` | vault Obsidian do user |
| Contexto desta sessao (RAM) | processo Claude Code | fim da conversa |

## Backward compat

| Antigo | Novo | Nota |
|--------|------|------|
| `zion` (CLI) | `leech` | alias `zion=leech` em init.sh |
| `~/.zion` | `~/.leech` | |
| `ZION_*` env vars | `LEECH_*` | |
| `zion-dk-*` containers | `leech-dk-*` | |
| `zion-tick` systemd | `leech-tick` | |
| GIT_COMMITTER_NAME | Zion | **mantido** (nao muda) |
