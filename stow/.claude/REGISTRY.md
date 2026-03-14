# Registry — stow/.claude/

Catálogo central de scripts, commands, skills, agents e hooks.

---

## Scripts (`scripts/`)

Scripts utilitários usados por statusline, hooks, agents e interativamente.
**Regra: todo script utilitário novo vai aqui.**

| Script | Tipo | Descrição |
|--------|------|-----------|
| `statusline.sh` | bash | Statusline: ctx \| $ \| Claudios (docker) \| Sessions (worker) \| alive \| modelo. **Métricas:** `docs/statusline-metrics.md` |
| `statusline-compact.sh` | bash | Statusline compacta: ctx, Claudios, Sessions. Modelo à direita |
| `colors.sh` | bash/lib | Definições ANSI (cores, bold, dim). `source scripts/colors.sh`. Respeita `NO_COLOR` |
| `logging.sh` | bash/lib | Logging estruturado: `log_info`, `log_warn`, `log_error`, `log_success`, `log_debug`, `log_step`. Source: `colors.sh` |
| `ansi.py` | python | Utilitários ANSI/unicode: `strip` (remove escapes), `vlen` (visual length), `calc` (math), `pad` (pad to width) |
| `gh-status.sh` | bash/lib | Coleta status GitHub (PRs meus, review requests) com cache 10min. `source gh-status.sh && gh_status_fetch` |
| `task-schedule.sh` | bash | Tabela de tasks agendadas por slot: recorrentes, pending, timeline próximas horas. `bash task-schedule.sh` |
| `weather-art.sh` | bash/lib | Weather fetch + ASCII art por condição (sol, chuva, nublado, etc). `source weather-art.sh` exporta WEATHER_ART[], WEATHER_CAT, dados |
| `usage-bar.sh` | bash | Gera `.ephemeral/usage-bar.txt`: uso API para bootstrap. **Fontes:** (1) Cursor /usage (Current, Resets) com `CURSOR_API_KEY` → `api.cursor.com/teams/spend`; (2) Anthropic tokens 30d com `ANTHROPIC_ADMIN_KEY` → `api-usage.sh`. Fallback: pede uma das duas keys. `USAGE_QUOTA_TOKENS`, `USAGE_BAR_PERIOD` |
| `claude-ai-usage.sh` | bash | Uso do plano via API web claude.ai (mesma fonte de Settings > Uso). **Session:** `CLAUDE_AI_SESSION_KEY` ou `~/.claude/claude-ai-session` ou `~/.config/claude-ai-session` (uma linha = cookie sessionKey). `--json` / `--debug`. Waybar: fallback do módulo `custom/claude`. |
| `rss-fetcher.py` | python | RSS aggregator stdlib-only: fetch RSS 2.0/Atom, dedup sha256, prune por idade, gera dashboard compacto. `--config feeds.md --data items.json --dashboard dash.txt` |
| `setup-opencode.sh` | bash | Setup opencode config via stow: install plugin `opencode-lmstudio`, sync config, run `bun install`. Uso: `bash scripts/setup-opencode.sh` |

---

## Commands (`commands/`)

Slash commands invocáveis pelo user via `/nome`.

### Meta
| Command | Invocação | Descrição |
|---------|-----------|-----------|
| `meta/manual` | `/manual` | Documentação de todos os skills e commands |
| `meta/diretrizes` | `/diretrizes` | Exibe DIRETRIZES.md |
| `meta/personality` | `/personality` | Toggle personalidade (SOUL.md) on/off |
| `meta/list-personalities` | `/list-personalities` | Lista personalidades disponíveis e exibe a ativa |
| `meta/list-avatars` | `/list-avatars` | Lista avatares disponíveis |
| `meta/propor` | `/propor` | Pitch de mudança em worktree isolado |
| `meta/suggestions` | `/suggestions` | Revisão de propostas de worktrees pendentes |
| `meta/auto-commit` | `/auto-commit` | Toggle auto-commit ON/OFF |
| `meta/auto-jarvis` | `/auto-jarvis` | Toggle auto-jarvis ON/OFF (executa /jarvis no startup) |
| `meta/contemplate` | `/contemplate` | Introspecção profunda — minera efêmeros e sessão pra extrair aprendizados |

### Global
| Command | Invocação | Descrição |
|---------|-----------|-----------|
| `jarvis` | `/jarvis` | Assistente pessoal — status GitHub, repos locais, THINKINGS, tasks, worktrees, recomendações |
| `rss` | `/rss` | Gerenciador RSS — `show`, `list`, `add <url> <cat> [max]`, `remove`, `fetch`, `config` |

### Utils
| Command | Invocação | Descrição |
|---------|-----------|-----------|
| `utils/worktree` | `/worktree` | Dashboard de worktrees — status atual + histórico |
| `utils/task` | `/task` | Gerenciar tarefas (criar, listar, status) |

### NixOS
| Command | Invocação | Descrição |
|---------|-----------|-----------|
| `nixos/add-pkg` | `/add-pkg` | Adiciona pacote ao NixOS (busca MCP + edita módulo + `nh os test`) |
| `nixos/remove-pkg` | `/remove-pkg` | Remove pacote do NixOS |
| `nixos/clean` | `/clean` | Garbage-collect Nix store + gerações antigas |
| `nixos/stow` | `/stow` | Gestão dotfiles com GNU Stow |

### Font
| Command | Invocação | Descrição |
|---------|-----------|-----------|
| `font/config` | `/font-config` | Teste iterativo de fontes para box-drawing |
| `font/testPage` | `/font-testPage` | Página de teste completa do terminal |

### Tools
| Command | Invocação | Descrição |
|---------|-----------|-----------|
| `tools/resumo-video` | `/resumo-video` | Resume vídeo YouTube via transcrição |

### Estratégia — Monolito (Go)
| Command | Invocação | Descrição |
|---------|-----------|-----------|
| `estrategia/mono/add-feature` | `/mono-add-feature` | Feature completa no monolito Go |
| `estrategia/mono/add-handler` | `/mono-add-handler` | Handler HTTP |
| `estrategia/mono/add-service` | `/mono-add-service` | Service layer |
| `estrategia/mono/add-repository` | `/mono-add-repository` | Repository + entity |
| `estrategia/mono/add-migration` | `/mono-add-migration` | SQL migration |
| `estrategia/mono/add-worker` | `/mono-add-worker` | Background worker |
| `estrategia/mono/review-code` | `/mono-review-code` | Code review Go |

### Estratégia — BO Container (Vue 2)
| Command | Invocação | Descrição |
|---------|-----------|-----------|
| `estrategia/bo/add-feature` | `/bo-add-feature` | Feature completa BO |
| `estrategia/bo/add-component` | `/bo-add-component` | Componente Vue 2 |
| `estrategia/bo/add-service` | `/bo-add-service` | Service API |
| `estrategia/bo/add-page` | `/bo-add-page` | Página/tela |
| `estrategia/bo/add-route` | `/bo-add-route` | Rota Vue Router |

### Estratégia — Front Student (Nuxt 2)
| Command | Invocação | Descrição |
|---------|-----------|-----------|
| `estrategia/front/add-feature` | `/front-add-feature` | Feature completa Front |
| `estrategia/front/add-component` | `/front-add-component` | Componente Nuxt 2 |
| `estrategia/front/add-service` | `/front-add-service` | Service API |
| `estrategia/front/add-page` | `/front-add-page` | Página Nuxt |
| `estrategia/front/add-route` | `/front-add-route` | Rota Nuxt |

### Estratégia — Orquestrador (cross-repo)
| Command | Invocação | Descrição |
|---------|-----------|-----------|
| `estrategia/orq/orquestrar-feature` | `/orquestrar-feature` | Feature cross-repo (mono+bo+front) |
| `estrategia/orq/retomar-feature` | `/retomar-feature` | Retomar feature em andamento |
| `estrategia/orq/review-pr` | `/review-pr` | Review de PR |
| `estrategia/orq/refinar-bug` | `/refinar-bug` | Refinar bug report |
| `estrategia/orq/recommit` | `/recommit` | Reescrever commits |
| `estrategia/orq/changelog` | `/changelog` | Gerar changelog |

---

## Agents (`agents/`)

Agentes especializados invocáveis via `Agent` tool.

| Agent | Model | Descrição |
|-------|-------|-----------|
| `trashman` | haiku | Limpeza segura: scan workspace, archive reversível em `.trashbin/`, audit trail |
| `wiseman` | haiku | Knowledge graph: interconecta notas do vault com backlinks, tags, frontmatter |
| `nixos` | haiku | NixOS config: pacotes, módulos, opções, troubleshoot |
| `monolito` | — | Go monolith: handlers, services, repos, migrations, workers, mocks |
| `bo-container` | — | Vue 2 BO: services, routes, components, pages |
| `front-student` | — | Nuxt 2 Front: services, routes, components, pages |
| `orquestrador` | — | Cross-repo: coordena Monolito + BO + Front |
| `dreamman` | — | Agente de fundo: processamento autônomo |

---

## Hooks (`hooks/`)

| Hook | Evento | Descrição |
|------|--------|-----------|
| `startup-hook.sh` | `UserPromptSubmit` | Intercepta prompt "startup" → roda `bootstrap.sh` |
| `worktree-enter.json` | — | Config de entrada em worktree |

---

## Skills (`skills/`)

Skills são templates/knowledge base que commands consomem. Cada skill tem `SKILL.md` + `templates/`.

| Namespace | Skills | Descrição |
|-----------|--------|-----------|
| `monolito/` | go-handler, go-service, go-repository, go-migration, go-worker, make-feature, review-code | Patterns Go para o monolito |
| `bo-container/` | component, service, page, route, make-feature | Patterns Vue 2 para BO |
| `front-student/` | component, service, page, route, make-feature | Patterns Nuxt 2 para Front |
| `orquestrador/` | orquestrar-feature, retomar-feature, review-pr, refinar-bug, recommit, changelog | Patterns cross-repo |
| `hyprland-config/` | SKILL.md | Config Hyprland (keybinds, monitors, rules) |
| `nixos/` | SKILL.md | NixOS module patterns |

---

## Outros

| Item | Path | Descrição |
|------|------|-----------|
| `settings.json` | `stow/.claude/settings.json` | Config do projeto (statusLine, hooks, MCP) |
| `art/watamote-tomoko.txt` | `stow/.claude/art/` | ASCII art |
| `plugins/` | `stow/.claude/plugins/` | Marketplace plugins config |
