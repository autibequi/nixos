# front-student — Docker config

Config Docker versionada para o front-student (Nuxt 2 + Vue 2).

## Uso

```bash
leech docker run front-student              # sandbox (default)
leech docker run front-student --env=local  # dev local (aponta para monolito local)
leech docker run front-student --env=qa     # QA
leech docker logs front-student -f          # follow logs
leech docker stop front-student             # para o container
leech docker shell front-student            # shell no container
leech docker flush front-student            # remove container + imagem + volumes
```

## Pre-requisitos

### 1. NPM_TOKEN (obrigatorio)

O front-student usa pacotes privados `@estrategiahq/*` no GitHub Package Registry.
Configure em `~/.leech` ou no ambiente:

```bash
# ~/.leech
NPM_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

O token precisa ter scope `read:packages` no GitHub.

### 2. SSH agent (para dependencia git+ssh)

O pacote `frontend-libs` e instalado via `git+ssh://git@github.com/estrategiahq/...`.
O SSH agent do host deve estar rodando com a chave carregada:

```bash
eval $(ssh-agent)
ssh-add ~/.ssh/id_rsa
```

Verificar: `ssh-add -l` deve listar a chave.

## Primeira execucao

```bash
leech docker install front-student
leech docker run front-student
```

O `install` roda `npm install` com SSH + NPM_TOKEN no container.
O `run` sobe o Nuxt dev server na porta 8082.

**Acesso:** `http://localhost:3005`

## Hot-reload

O source `${FRONT_STUDENT_DIR}` e montado como bind mount.
Salvar qualquer arquivo aciona o HMR automaticamente.

Os `node_modules` ficam no projeto (gerados por `leech docker install`).

## Atualizar dependencias (apos mudar package.json)

```bash
leech docker install front-student
leech docker restart front-student
```

Ou flush completo:

```bash
leech docker flush front-student
leech docker install front-student
leech docker run front-student
```

## Arquitetura

```mermaid
graph TD
    subgraph HOST["Host NixOS"]
        LeechCLI["leech CLI"]
        LeechCFG["~/.leech\nFRONT_STUDENT_DIR · NPM_TOKEN"]
        LOGS["~/.local/share/leech/logs/dockerized/front-student/\nservice.log · test.log · startup.log"]
        SSHAgent["SSH Agent\n(git+ssh deps)"]
    end

    subgraph COMPOSE["Docker Compose — leech-dk-front-student"]
        APP["app container\nleech-dk-front-student-app\n:8082 HTTP (Nuxt dev)"]
    end

    subgraph BUILD["Build (docker compose build)"]
        DF["Dockerfile\nnode:20-alpine"]
    end

    LeechCFG --> LeechCLI
    LeechCLI -->|"docker run front-student"| APP
    APP --> DF
    APP -->|"bind mount src/"| HOST
    APP -->|"nohup logs"| LOGS
```

## Env files

- `env/sandbox.env` — sandbox (default) — APIs de sandbox
- `env/local.env` — local — APIs locais + containers Docker da rede nixos_default
- `env/qa.env` — QA
- `env/prod.env` — producao (template — sem segredos)

## Path do projeto

Configurar em `~/.leech`:
```bash
FRONT_STUDENT_DIR="$HOME/projects/estrategia/front-student"
```

## Detalhes tecnicos

- Node 20 Alpine
- Nuxt 2 + Vue 2
- Dev server HTTP em `:3005` (porta hardcoded no nuxt.config.js)
- `nuxt dev` executado diretamente — vars vem do Docker env_file
- Hot-reload via bind mount do source

## Logs

- Host: `~/.local/share/leech/logs/dockerized/front-student/`
- Container (agente): `/workspace/logs/docker/front-student/`
- Arquivos: `service.log`, `test.log`, `startup.log`
