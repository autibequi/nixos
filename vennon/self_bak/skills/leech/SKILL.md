---
name: leech
description: Skill composta do sistema Leech — infraestrutura, containers, CLI, ambiente. Indice das sub-skills de operacao do proprio Leech (nao dos projetos que rodam dentro dele).
---

# Leech — Skill Composta

Skills sobre o sistema Leech em si: containers, CLI, logs, ambiente.

## Sub-skills

| Sub-skill | Quando usar |
|---|---|
| `leech/container` | Dockerizar novo servico integrado ao Leech OU operar servicos existentes via `vennon` |
| `leech/linux` | NixOS, Hyprland, Waybar, dotfiles, stow, debug de host — tudo de sistema Linux |
| `leech/healthcheck` | Diagnostico do sistema — ferramentas, disco, load, workspace, git, tasks, cleanup |
| `leech/upgrade` | Implementar e depurar uma feature do Leech de forma autonoma — worktree isolado, testes sem supervisao, entrega de branch pronto |
| `leech/worktree` | Sessoes multi-repo para features da Estrategia — `leech wt new/switch/list/close` |

## O que e o Leech (contexto rapido)

```
/workspace/self/        ← engine: prompts, skills, agents, commands
/workspace/home/         ← zona de trabalho (projeto do usuario)
/workspace/obsidian/    ← cerebro persistente (vault Obsidian)
/workspace/logs/        ← logs montados do host
/workspace/.hive-mind/  ← area efemera compartilhada entre containers
```

## Configuracao — Figment layered

**Prioridade:** CLI flag > env var (`LEECH_*`) > config.yaml > built-in default

| Fonte | Path | Conteudo |
|---|---|---|
| config.yaml | `~/.config/leech/config.yaml` | Defaults estruturados (session, runner, agents, paths, system) |
| env vars | `LEECH_SESSION_ENGINE`, `LEECH_RUNNER_ENV`, etc. | Override pontual |
| secrets | `GH_TOKEN`, `ANTHROPIC_API_KEY` (env vars diretas) | Tokens — nunca no YAML |
| ~/.leech | `~/.leech` | Legado bash-sourceable (tokens + backward compat) |

Gerenciar config: `leech config show|edit|init|path`

## CLI — 4 dominios

### Session
| Comando | O que faz |
|---|---|
| `yaa` | Nova sessao Claude Code (default) |
| `leech --opus` | Sessao com modelo Opus |
| `yaa continue` | Retomar ultima sessao |
| `leech resume [--resume=ID]` | Retomar por ID |
| `yaa shell` | Bash no container |
| `leech ask [agent] pergunta` | Pergunta one-shot |

### Agents
| Comando | O que faz |
|---|---|
| `yaa agents` | Listar agentes |
| `yaa agents phone <nome>` | Conversa interativa |
| `yaa agents status [nome]` | Activity log |
| `yaa phone <nome> [-s N]` | Rodar agente/task agora |
| `yaa tick [--dry-run]` | Executar trabalho pendente |
| `yaa tasks` | Kanban DOING/TODO/DONE |

### Services
| Comando | O que faz |
|---|---|
| `vennon <svc> <action>` | Orquestrar servico Docker (start/stop/logs/shell/test/install/build/flush) |
| `deck` | Dashboard interativo (TUI) |
| `leech worktree [svc]` | Listar git worktrees |

### System
| Comando | O que faz |
|---|---|
| `vennon build\|stop\|clean\|destroy` | Lifecycle do container Leech |
| `deck os switch\|test\|boot\|build` | Operacoes NixOS |
| `deck stow [-r]` | Deploy dotfiles |
| `leech config` | Ver/editar configuracao |
| `yaa man` | Documentacao completa |

## Regras de ambiente

- `in_docker=1` → nao executar `nixos-rebuild`, `nh os switch`, `systemctl` — nao afeta o host
- Para comandos de sistema: pedir ao usuario rodar no host
- `nix-shell -p <pkg>` disponivel no container para qualquer pacote Nixpkgs
- Scripts: editar `leech/scripts/` (fonte da verdade), nunca `scripts/` (sao symlinks)
- `host_attached=1`: `/workspace/host/` editavel — skills, hooks, agents, CLI do Leech
- Ativar: `leech --host`, `yaa --host`, ou `session.host: true` em `config.yaml`
- `/workspace/obsidian/` sempre editavel por qualquer agente (sem precisar de --host)

## Logs — onde ficam

| Path no container | Conteudo |
|---|---|
| `/workspace/logs/docker/<service>/service.log` | Runtime |
| `/workspace/logs/docker/<service>/startup.log` | Build/startup |
| `/workspace/logs/docker/<service>/install.log` | go mod / npm |

Host: `~/.local/share/leech/logs/<service>/`

## Rede entre containers

Todos os containers Leech usam a rede externa `nixos_default`:
```yaml
networks:
  default:
    name: nixos_default
    external: true
```

## Adicionar nova sub-skill

Criar `leech/<nome>/SKILL.md` e referenciar nesta tabela.
