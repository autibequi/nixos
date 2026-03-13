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

| Repo | Path | Skills Disponiveis |
|---|---|---|
| monolito | /home/claude/projects/estrategia/monolito | monolito/go-service, go-handler, go-migration, go-repository, go-worker, make-feature, review-code |
| bo-container | /home/claude/projects/estrategia/bo-container | bo-container/service, route, component, page, make-feature |
| front-student | /home/claude/projects/estrategia/front-student | front-student/service, route, component, page, make-feature |
| (cross-repo) | todos acima | orquestrador/* |

## Deteccao de Repo
1. Se cwd esta sob /home/claude/projects/estrategia/<repo>/ → repo identificado
2. `git remote get-url origin` contem `estrategiahq/<repo>`
3. User menciona nome do repo → consultar tabela acima

## Adicionando Novo Repo/Skill
1. Criar diretorio em `stow/.claude/skills/estrategia/<repo>/`
2. Adicionar entrada na tabela acima
3. Cada SKILL.md deve ter `name: <repo>/<skill-name>`
