---
name: dockerizer
description: "Analisa um projeto e gera infraestrutura Docker completa (Dockerfile, compose, .env, registro no Zion CLI)"
---

# /dockerizer

Skill de containerizacao para o Zion. Analisa o projeto atual e gera toda a infraestrutura Docker necessaria.

## O que faz

1. Detecta linguagem/framework do projeto
2. Identifica entrypoints (server, worker, etc.)
3. Mapeia dependencias externas (DB, Redis, SQS, etc.)
4. Gera Dockerfile otimizado (multi-stage build)
5. Gera docker-compose.yml + docker-compose.deps.yml
6. Gera .env templates por ambiente (sand, local, qa, prod)
7. Registra no Zion CLI (`docker_services.sh`)
8. Testa build + up + logs

## Uso

```
/dockerizer
```

Rode dentro do diretorio do projeto que quer containerizar. O agente vai analisar e gerar tudo em `zion/dockerized/<service>/`.

## Referencia

Skill completa: `zion/skills/dockerizer/SKILL.md`
