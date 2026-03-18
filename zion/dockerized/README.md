# Zion Dockerized Services

Configs Docker versionadas para servicos da estrategia. Cada servico tem seu proprio diretorio com compose, Dockerfile, env files e scripts de init.

## Servicos

| Servico | Status | Descricao |
|---------|--------|-----------|
| monolito | ativo | Go monolith (app + worker + deps) |
| bo-container | futuro | Vue 2 backoffice |
| front-student | futuro | Nuxt 2 frontend |

## Uso

```bash
zion docker run monolito --env=sand    # levanta app + deps
zion docker logs monolito -f           # follow logs
zion docker status                     # lista containers rodando
zion docker stop monolito              # para tudo
zion docker shell monolito             # shell no container app
zion docker restart monolito --env=qa  # restart com outro env
```

## Estrutura

```
zion/dockerized/
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

Paths dos projetos em `~/.zion`:
```bash
MONOLITO_DIR="$HOME/projects/estrategia/monolito"
BO_CONTAINER_DIR="$HOME/projects/estrategia/bo-container"
FRONT_STUDENT_DIR="$HOME/projects/estrategia/front-student"
```
