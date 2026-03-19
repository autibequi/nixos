# zion CLI (bashly)

CLI unificado para o container Claude: sessões interativas, workers, build e tasks.

## Instalação

`zion update` — regenera o script (bashly) e cria/atualiza o symlink em `stow/.local/bin/zion`. Após stow, `~/.local/bin/zion` aponta para o script no repo.

## Desenvolvimento

- Editar `src/bashly.yml`, `src/commands/*.sh`, `src/lib/compose_lib.sh`
- Regenerar: `zion update` (ou `cd cli && bashly generate`)

## Configuração (~/.zion)

Config do usuário: **~/.zion** (KEY=value, sourceável). Para criar a partir do exemplo:

```bash
zion init          # cria ~/.zion (não sobrescreve)
zion init --force  # sobrescreve se já existir
```

Depois edite e preencha `engine=`, `GH_TOKEN=`, `ANTHROPIC_API_KEY=` (chmod 600 é aplicado pelo init).

- **engine** — padrão para sessão: `opencode` | `claude` | `cursor`
- **GH_TOKEN**, **ANTHROPIC_API_KEY** — injetados no container (não usar mais .env do repo para chaves)
- **CURSOR_API_KEY** (opcional) — para engine `cursor`; alternativamente use login no host (`agent login`) e monte `~/.cursor` (já montado pelo compose)
- **OBSIDIAN_PATH** (opcional) — caminho do vault Obsidian; se não definir, usa `~/.ovault/Zion`. Necessário para montar `/obsidian` no container. O host (repo nixos) é sempre montado em `/nixos` via `$HOME/nixos`.

Sem `--engine=` na linha de comando, `zion run` usa `engine=` de ~/.zion; se não houver, exige `--engine=`.

## Subcomandos

### Sessão (interativo)
| Comando   | Alias        | Descrição |
|----------|---------------|-----------|
| run      | r, open, opencode, code (default) | Sessão no container; **exige --engine=opencode\|claude\|cursor** (ou engine= em ~/.zion) |
| shell    | sh            | Bash no container |
| resume   | —             | Claude --resume |
| continue | cont          | Claude --continue |
| start    | —             | Sandbox persistente + Claude |
| openclaw | —             | OpenClaw gateway |

### Container
| Comando  | Descrição |
|----------|-----------|
| build    | Build da imagem Docker |
| down     | Para containers do projeto |
| destroy  | Para containers + remove imagens/volumes |
| update   | Regenera CLI e symlink |

### Workers / tasks
| Comando          | Alias | Descrição |
|------------------|-------|-----------|
| worker [task]    | w     | Worker every60 com output; task opcional; aceita --engine= |
| worker-run-fast  | wrf   | Worker every10 com output |
| worker-auto      | —     | 1 worker every60 headless |
| worker-clau      | —     | 2 workers every60 em background |
| worker-stop      | —     | Para workers + reset tasks |
| worker-stop-all  | —     | Para todos os containers sandbox |
| reset            | —     | Devolve tasks running → pending |
| status           | —     | Estado kanban + workers |
| new \<name\>     | —     | Cria task + card (--type, --model, --clock, --timeout) |

### Logs / uso
| Comando      | Descrição |
|--------------|-----------|
| logs         | Último log (ou follow) |
| logs-list    | Lista logs |
| usage-api    | Uso API Anthropic (--7d, --30d) |
| service-logs | journalctl claude-autonomous |
| ask [pergunta] | Claude em Alacritty |

Flags globais: `--engine=opencode|claude|cursor`, `--model=haiku|opus`, `--instance ID`, `--rw`, `--ro`, `--danger`.

- **`--danger`** — bypass de permissões no engine: **claude** = `--permission-mode bypassPermissions`; **cursor** = `--force` (auto-approve); **opencode** = env `OPENCODE_PERMISSION_BYPASS=1` (se o binário suportar). Sem a flag, o engine pede confirmação conforme config. Em **~/.zion** use **`DANGER=true`** para deixar danger sempre ligado (equiv. a passar `--danger` em todo run/resume/continue).

### Engine Cursor (Cursor CLI)

Com `engine=cursor`, o `zion run` sobe o **Cursor CLI** (`agent`) no container, com o projeto em `/workspace`. Autenticação:

- **Montagem** — o compose monta `~/.cursor` do host (config) e usa o volume nomeado `cursor_config` para `~/.config/cursor` (tokens). Bind mount do host em `.config/cursor` causaria EPERM porque o agent faz chmod nesse dir; o volume nomeado permite isso e persiste o login entre runs.
- **API key** — defina `CURSOR_API_KEY=...` em `~/.zion` (ou no `.env` do cli) para uso em scripts/headless.

**Verificar autenticação (uma vez):** dentro do container, rode `agent status` (ex.: `zion run --engine=cursor /tmp` e depois `agent status`; ou `docker compose -f docker-compose.zion.yml run --rm sandbox agent status` no dir do compose). Confirme que aparece autenticado antes de usar em fluxo real.
