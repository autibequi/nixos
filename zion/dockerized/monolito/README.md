# Monolito — Docker config

Config Docker versionada para o monolito Go da estrategia.

## Servicos

- **app** — servidor HTTP (porta 4004) + Delve debugger (porta 2345)
- **worker** — worker de filas/jobs
- **postgres** — PostgreSQL 16
- **redis** — Redis 7
- **localstack** — SQS + S3 local

## Uso

```bash
zion docker run monolito             # sandbox (default)
zion docker run monolito --env=local # dev local
zion docker run monolito --env=qa    # QA
zion docker logs monolito -f         # follow logs
zion docker stop monolito            # para tudo
zion docker shell monolito           # shell no app
zion docker shell monolito postgres  # shell no postgres
```

## Env files

- `env/sand.env` — sandbox (deps em containers, endpoints locais)
- `env/local.env` — localhost (deps no host)
- `env/qa.env` — QA
- `env/prod.env` — template producao (segredos via .env.local)

## Path do projeto

Configurar em `~/.zion`:
```bash
MONOLITO_DIR="$HOME/projects/estrategia/monolito"
```
