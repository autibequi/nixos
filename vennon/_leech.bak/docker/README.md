# Leech Dockerized Services

Configs Docker versionadas para servicos da estrategia. Cada servico tem seu proprio diretorio com compose, Dockerfile, env files e scripts de init.

## Servicos

| Servico | Status | Descricao |
|---------|--------|-----------|
| monolito | ativo | Go monolith (app + worker + deps) |
| bo-container | ativo | Vue 2 backoffice |
| front-student | ativo | Nuxt 2 frontend |

## Uso

```bash
leech docker run monolito --env=sand    # levanta app + deps
leech docker logs monolito -f           # follow logs
leech docker status                     # lista containers rodando
leech docker stop monolito              # para tudo
leech docker shell monolito             # shell no container app
leech docker restart monolito --env=qa  # restart com outro env
```

## Estrutura

```
leech/containers/
├── _shared/networks.yml         # networks compartilhadas
├── monolito/
│   ├── docker-compose.yml       # app + worker
│   ├── docker-compose.deps.yml  # postgres, redis, localstack
│   ├── Dockerfile               # multi-stage Go build
│   ├── env/{sand,local,qa,prod}.env
│   ├── init/                    # init scripts (DB, etc)
│   └── README.md
```

## Config

Paths dos projetos em `~/.leech`:
```bash
MONOLITO_DIR="$HOME/projects/estrategia/monolito"
BO_CONTAINER_DIR="$HOME/projects/estrategia/bo-container"
FRONT_STUDENT_DIR="$HOME/projects/estrategia/front-student"
```
