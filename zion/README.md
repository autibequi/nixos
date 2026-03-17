# Zion

Engine que roda as IAs no container. Comando principal: **`zion`** (ex.: `zion --help`).

## Layout no container: pasta zion na raiz do filesystem

A pasta **zion** fica montada em **`/zion`** (raiz do filesystem). Dentro do container:

- **`/zion`** — raiz da engine (bootstrap: `/zion/bootstrap.md`, comandos: `/zion/commands/`, scripts: `/zion/scripts/`)
- **`/nixos`** — configuração NixOS do host (raiz do repo)
- **`/logs`** — logs do host
- **`/obsidian`** — vault Obsidian compartilhado

## Estrutura

- **`docker-compose.zion.yml`** — monta a pasta zion em **`/zion`** e a raiz do repo em `/nixos`; monta `.claude`, `.cursor` e `.opencode` em `/root/` para os agentes. Rodar na raiz do repo: `docker compose -f zion/docker-compose.zion.yml run --rm zion`. O CLI invoca `/zion/scripts/bootstrap.sh`.
- **`bootstrap.md`** — instruções para o agente (ler ao receber `/zion` ou `/zion load`).
- **`commands/`** — comandos por categoria (zion, estrategia, meta, nixos, tools, utils, etc.).
- **`scripts/`** — bootstrap.sh e outros scripts.
- **`.cursor/`** — regra e comando do `/zion` para o Cursor (rules, commands).
- **`zion-alias.zsh`** — alias `claudio=zion` para retrocompatibilidade; adicione ao `~/.zshrc` ou `source /zion/zion-alias.zsh`.

## Comando /zion no Cursor

Para o Cursor reconhecer `/zion` e `/zion load`, use a regra e o comando em **`/zion/.cursor/`** (copie ou linke para o `.cursor` do seu projeto, se quiser).
