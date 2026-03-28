# Leech

Engine que roda as IAs no container. Comando principal: **`leech`** (ex.: `leech --help`).

## Layout no container: pasta leech na raiz do filesystem

A pasta **leech** fica montada em **`/leech`** (raiz do filesystem). Dentro do container:

- **`/leech`** — raiz da engine (comandos: `/leech/commands/`, scripts: `/leech/scripts/`)
- **`/nixos`** — configuração NixOS do host (raiz do repo)
- **`/logs`** — logs do host
- **`/obsidian`** — vault Obsidian compartilhado

## Estrutura

- **`docker-compose.leech.yml`** — monta a pasta leech em **`/leech`** e a raiz do repo em `/nixos`; monta `.claude`, `.cursor` e `.opencode` em `/root/` para os agentes. Rodar na raiz do repo: `docker compose -f leech/docker-compose.leech.yml run --rm leech`. O CLI invoca `/leech/scripts/bootstrap.sh`.
- **`commands/`** — comandos por categoria (load, estrategia, meta, nixos, tools, utils, etc.).
- **`scripts/`** — bootstrap.sh e outros scripts.
- **`.cursor/`** — regra e comando do `/load` para o Cursor (rules, commands).
- **Comando:** `leech` (PATH em stow/.local/bin; use `leech update` ou make install no host).

## Comando /load no Cursor

Para o Cursor reconhecer `/load` e `/load <nome>`, use a regra e o comando em **`/leech/.cursor/`** (copie ou linke para o `.cursor` do seu projeto, se quiser). O boot do agente está em **`/leech/commands/load.md`**.
