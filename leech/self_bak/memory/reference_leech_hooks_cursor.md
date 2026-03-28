# Leech: hooks unificados + Cursor + Docker

**Fonte da verdade:** `leech/self/hooks/` (repo host: `nixos/leech/self/hooks`).

## Layout

| Destino no container | Origem bind |
|----------------------|-------------|
| `~/.claude/hooks/` | `self/hooks/` (tudo: `session-start.sh`, `pre-tool-use.sh`, `post-tool-use.sh`, `user-prompt-submit.sh`, …) |
| `~/.cursor/leech-hooks/` | **`self/hooks/cursor/`** só (`cursor-hook.sh` + `cursor/README.md`) |
| `~/.cursor/hooks.json` | `self/hooks/cursor/hooks.json` |
| `~/.cursor/skills` | `self/skills` (montagem total; par com `~/.claude/skills`) |

## `ENGINE`

Exportado nos scripts: `CLAUDE` (default), `CURSOR` (wrappers Cursor), `OPENCODE` (futuro / `~/.leech`). Aparece no `---BOOT---` como `engine=...`.

## `cursor-hook.sh`

Único entrypoint Cursor: subcomandos `sessionStart` | `preToolUse` | `postToolUse`. Define `ENGINE=CURSOR`, delega para `../session-start.sh` etc. Ramo `sessionStart` embala o boot em JSON `additional_context` — necessário porque o Cursor exige JSON no stdout; não dá só apontar o `hooks.json` ao `session-start.sh` cru.

## Compose

`docker/leech/docker-compose.leech.yml` e `docker-compose.ghost.yml`. Alterar mounts → **recriar** o container (`--force-recreate`).

## Symlink host

Se `~/.claude/hooks` apontava para `.../hooks/claude-code`, atualizar para `.../hooks` (pasta unificada; `claude-code/` foi removida).
