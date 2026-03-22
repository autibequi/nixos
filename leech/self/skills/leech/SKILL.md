---
name: leech
description: Skill composta do sistema Leech — infraestrutura, containers, CLI, ambiente. Indice das sub-skills de operacao do proprio Leech (nao dos projetos que rodam dentro dele).
---

# Leech — Skill Composta

Skills sobre o sistema Leech em si: containers, CLI, logs, ambiente, lab mode.

## Sub-skills

| Sub-skill | Quando usar |
|---|---|
| `leech/container` | Dockerizar novo servico integrado ao Leech OU operar servicos existentes via `leech docker` |
| `leech/linux` | NixOS, Hyprland, Waybar, dotfiles, stow, debug de host — tudo de sistema Linux |
| `leech/healthcheck` | Diagnostico do sistema — ferramentas, disco, load, workspace, git, tasks, cleanup |

## O que e o Leech (contexto rapido)

```
/workspace/self/        ← engine: prompts, skills, agents, commands
/workspace/mnt/         ← zona de trabalho (projeto do usuario)
/workspace/obsidian/    ← cerebro persistente (vault Obsidian)
/workspace/logs/        ← logs montados do host
/workspace/.hive-mind/  ← area efemera compartilhada entre containers
```

CLI principal: `leech <comando>`

| Comando | O que faz |
|---|---|
| `leech docker run <service>` | Levanta container |
| `leech docker status` | Status de todos os containers |
| `leech docker logs <service>` | Logs do container |
| `leech docker stop/restart/flush` | Gerenciar ciclo de vida |
| `leech docker install <service>` | Instalar deps (go vendor, npm) |
| `leech docker shell <service>` | Shell interativo |
| `leech stow` | Aplicar dotfiles do nixos/stow no host |
| `leech switch` | Rebuild NixOS no host |
| `leech agents run <nome>` | Disparar agente |

## Regras de ambiente

- `in_docker=1` → nao executar `nixos-rebuild`, `nh os switch`, `systemctl` — nao afeta o host
- Para comandos de sistema: pedir ao usuario rodar no host
- `nix-shell -p <pkg>` disponivel no container para qualquer pacote Nixpkgs
- Scripts: editar `leech/scripts/` (fonte da verdade), nunca `scripts/` (sao symlinks)
- `leech_edit=1` (lab mode): `/workspace/host/` editavel — skills, hooks, agents, CLI

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
