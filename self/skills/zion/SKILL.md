---
name: zion
description: Skill composta do sistema Zion — infraestrutura, containers, CLI, ambiente. Indice das sub-skills de operacao do proprio Zion (nao dos projetos que rodam dentro dele).
---

# Zion — Skill Composta

Skills sobre o sistema Zion em si: containers, CLI, logs, ambiente, lab mode.

## Sub-skills

| Sub-skill | Quando usar |
|---|---|
| `zion/container` | Dockerizar novo servico integrado ao Zion OU operar servicos existentes via `zion docker` |
| `zion/linux` | NixOS, Hyprland, Waybar, dotfiles, stow, debug de host — tudo de sistema Linux |

## O que e o Zion (contexto rapido)

```
/workspace/self/        ← engine: prompts, skills, agents, commands
/workspace/mnt/         ← zona de trabalho (projeto do usuario)
/workspace/obsidian/    ← cerebro persistente (vault Obsidian)
/workspace/logs/        ← logs montados do host
/workspace/.hive-mind/  ← area efemera compartilhada entre containers
```

CLI principal: `zion <comando>`

| Comando | O que faz |
|---|---|
| `zion docker run <service>` | Levanta container |
| `zion docker status` | Status de todos os containers |
| `zion docker logs <service>` | Logs do container |
| `zion docker stop/restart/flush` | Gerenciar ciclo de vida |
| `zion docker install <service>` | Instalar deps (go vendor, npm) |
| `zion docker shell <service>` | Shell interativo |
| `zion stow` | Aplicar dotfiles do nixos/stow no host |
| `zion switch` | Rebuild NixOS no host |
| `zion agents run <nome>` | Disparar agente |

## Regras de ambiente

- `in_docker=1` → nao executar `nixos-rebuild`, `nh os switch`, `systemctl` — nao afeta o host
- Para comandos de sistema: pedir ao usuario rodar no host
- `nix-shell -p <pkg>` disponivel no container para qualquer pacote Nixpkgs
- Scripts: editar `zion/scripts/` (fonte da verdade), nunca `scripts/` (sao symlinks)
- `zion_edit=1` (lab mode): `/workspace/host/` editavel — skills, hooks, agents, CLI

## Logs — onde ficam

| Path no container | Conteudo |
|---|---|
| `/workspace/logs/docker/<service>/service.log` | Runtime |
| `/workspace/logs/docker/<service>/startup.log` | Build/startup |
| `/workspace/logs/docker/<service>/install.log` | go mod / npm |

Host: `~/.local/share/zion/logs/<service>/`

## Rede entre containers

Todos os containers Zion usam a rede externa `nixos_default`:
```yaml
networks:
  default:
    name: nixos_default
    external: true
```

## Adicionar nova sub-skill

Criar `zion/<nome>/SKILL.md` e referenciar nesta tabela.
