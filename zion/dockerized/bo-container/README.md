# bo-container — Docker config

Config Docker versionada para o bo-container (Vue 2 + Quasar 1.x).

## Uso

```bash
zion docker run bo-container              # sandbox (default)
zion docker run bo-container --env=local  # dev local (aponta para monolito local)
zion docker run bo-container --env=qa     # QA
zion docker logs bo-container -f          # follow logs
zion docker stop bo-container             # para o container
zion docker shell bo-container            # shell no container
zion docker flush bo-container            # remove container + imagem + volumes
```

## Pre-requisitos

### 1. NPM_TOKEN (obrigatorio)

O bo-container usa pacotes privados `@estrategiahq/*` no GitHub Package Registry.
Configure em `~/.zion` ou no ambiente:

```bash
# ~/.zion
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
zion docker run bo-container
```

O `docker compose build` vai:
1. Instalar dependencias (`npm install`) com SSH + NPM_TOKEN
2. Copiar o source para a imagem
3. Subir o servidor Quasar dev na porta 9090

**Acesso:** `https://localhost:9090` (certificado auto-assinado — aceitar aviso no browser)

## Hot-reload

O source `${BO_CONTAINER_DIR}` e montado como bind mount.
Salvar qualquer arquivo em `src/` aciona o HMR automaticamente.

Os `node_modules` ficam num volume anonimo preservado entre restarts.

## Atualizar dependencias (apos mudar package.json)

```bash
zion docker flush bo-container
zion docker run bo-container
```

O flush remove o volume de node_modules. O proximo `run` reinstala tudo.

## Arquitetura

```mermaid
graph TD
    subgraph HOST["Host NixOS"]
        ZionCLI["zion CLI"]
        ZionCFG["~/.zion\nBO_CONTAINER_DIR · NPM_TOKEN"]
        LOGS["/tmp/zion-logs/dockerized/bo-container/\nservice.log · test.log · startup.log"]
        SSHAgent["SSH Agent\n(git+ssh deps)"]
    end

    subgraph COMPOSE["Docker Compose — zion-dk-bo-container"]
        APP["app container\nzion-dk-bo-container-app\n:9090 HTTPS (Quasar dev)"]
        NM[("node_modules volume\n(anonimo — preservado)")]
    end

    subgraph BUILD["Build (docker compose build)"]
        DF["Dockerfile\nnode:14-alpine\nnpm install (SSH + NPM_TOKEN)"]
    end

    ZionCFG --> ZionCLI
    SSHAgent -->|"--mount=type=ssh"| DF
    ZionCLI -->|"docker run bo-container"| APP
    APP --> DF
    APP --- NM
    APP -->|"bind mount src/"| HOST
    APP -->|"nohup logs"| LOGS
```

## Env files

- `env/sand.env` — sandbox (default) — APIs de sandbox
- `env/local.env` — local — APIs locais + containers Docker da rede nixos_default
- `env/qa.env` — QA
- `env/prod.env` — producao (template — sem segredos)

## Path do projeto

Configurar em `~/.zion`:
```bash
BO_CONTAINER_DIR="$HOME/projects/estrategia/bo-container"
```

## Detalhes tecnicos

- Node 14 Alpine (conforme `engines` no package.json)
- Quasar 1.x + Vue 2
- Dev server HTTPS em `:9090` (hardcoded em `quasar.conf.js`)
- `LOCAL_BO_CONTAINER_HOST=0.0.0.0` para bind em todas as interfaces
- `quasar dev` executado diretamente (sem `env-cmd`) — vars vem do Docker env_file
- Hot-reload via bind mount do source

## Logs

- Host: `/tmp/zion-logs/dockerized/bo-container/`
- Container (agente): `/workspace/logs/docker/bo-container/`
- Arquivos: `service.log`, `test.log`, `startup.log`
