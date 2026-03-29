# Hooks vennon (unificado)

**Claude Code** usa `self/hooks/` em `~/.claude/hooks/`. **Cursor** usa só `self/hooks/cursor/` montado em `~/.cursor/vennon-hooks/` + `hooks.json` (ver `cursor/README.md`). O runtime expõe **`ENGINE`** nos scripts.

## `ENGINE`

| Valor     | Quando |
|-----------|--------|
| `CLAUDE`  | Default; hook SessionStart / PreTool / PostTool do Claude Code |
| `CURSOR`  | `hooks/cursor/cursor-hook.sh` + `hooks.json` do Cursor |
| `OPENCODE`| Podes definir em `~/.vennon` quando integrares esse runtime |

O bloco `---BOOT---` inclui `engine=...` para o modelo saber em que modo o vennon está.

## Ficheiros

| Ficheiro | Uso |
|----------|-----|
| `session-start.sh` | Boot completo (stdout texto; espelho `.cursor/session-boot.md`) |
| `cursor/cursor-hook.sh` | Entrypoint Cursor (JSON) → delega aos `.sh` desta pasta |
| `pre-tool-use.sh` / `post-tool-use.sh` | Lógica comum; formato de saída depende de `ENGINE` |
| `user-prompt-submit.sh` | Claude UserPromptSubmit |
| `startup-hook.sh` | Claude startup |
| `worktree-enter.json` | Claude worktree |
| `cursor/hooks.json` | Manifest Cursor — `~/.cursor/hooks.json` no container |

## Docker

No `docker-compose.vennon.yml`:

- `self/hooks` → `/home/claude/.claude/hooks`
- `self/hooks/cursor` → `/home/claude/.cursor/vennon-hooks`
- `self/hooks/cursor/hooks.json` → `~/.cursor/hooks.json`
- **`self/skills`** → **`~/.cursor/skills`** (igual a `~/.claude/skills`; montagem total no container)
