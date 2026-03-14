---
name: estrategia/registry
description: Leia SEMPRE que for trabalhar num projeto da Estrategia. Contem mapeamento de repos, skills disponiveis, e como descobrir o repo certo.
---

# Estrategia — Registry de Skills e Repos

## Base Path
/home/claude/projects/estrategia/

## GitHub Org
estrategiahq

## Repos e Skills

| Repo | Repo Path | Agent | Skills Path | Skills Disponiveis |
|---|---|---|---|---|
| monolito | /home/claude/projects/estrategia/monolito | `stow/.claude/agents/monolito/` | `stow/.claude/agents/monolito/skills/` | go-service, go-handler, go-migration, go-repository, go-worker, make-feature, review-code |
| bo-container | /home/claude/projects/estrategia/bo-container | `stow/.claude/agents/bo-container/` | `stow/.claude/agents/bo-container/skills/` | service, route, component, page, make-feature |
| front-student | /home/claude/projects/estrategia/front-student | `stow/.claude/agents/front-student/` | `stow/.claude/agents/front-student/skills/` | service, route, component, page, make-feature |
| (cross-repo) | todos acima | N/A | `stow/.claude/skills/estrategia/orquestrador/` | orquestrador/* |

## Deteccao de Repo
1. Se cwd esta sob /home/claude/projects/estrategia/<repo>/ → repo identificado
2. `git remote get-url origin` contem `estrategiahq/<repo>`
3. User menciona nome do repo → consultar tabela acima

## Adicionando Novo Repo/Skill
1. Criar diretorio em `stow/.claude/agents/<repo>/skills/<skill-name>/`
2. Cada SKILL.md deve ter `name: <repo>/<skill-name>`
3. Agentes auto-descobrem skills em seu diretorio `skills/`
