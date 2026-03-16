# claudio CLI (bashly)

CLI unificado para o container Claude: sessões interativas, workers, build e tasks.

## Instalação

`claudio install` — regenera o script (bashly) e cria/atualiza o symlink em `stow/.local/bin/claudio`. Após stow, `~/.local/bin/claudio` aponta para o script no repo.

## Desenvolvimento

- Editar `src/bashly.yml`, `src/commands/*.sh`, `src/lib/compose_lib.sh`
- Regenerar: `claudio install` (ou `cd claudio-cli && bashly generate`)

## Configuração (~/.claudio)

Config do usuário: **~/.claudio** (KEY=value, sourceável). Para criar a partir do exemplo:

```bash
claudio init          # cria ~/.claudio (não sobrescreve)
claudio init --force  # sobrescreve se já existir
```

Depois edite e preencha `engine=`, `GH_TOKEN=`, `ANTHROPIC_API_KEY=` (chmod 600 é aplicado pelo init).

- **engine** — padrão para sessão: `opencode` | `claude` | `cursor`
- **GH_TOKEN**, **ANTHROPIC_API_KEY** — injetados no container (não usar mais .env do repo para chaves)
- **OBSIDIAN_PATH** (opcional)

Sem `--engine=` na linha de comando, `claudio run` usa `engine=` de ~/.claudio; se não houver, exige `--engine=`.

## Subcomandos

### Sessão (interativo)
| Comando   | Alias        | Descrição |
|----------|---------------|-----------|
| run      | r, open, opencode, code (default) | Sessão no container; **exige --engine=opencode\|claude\|cursor** (ou engine= em ~/.claudio) |
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
| install  | Regenera CLI e symlink |

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

Flags globais: `--engine=opencode|claude|cursor`, `--model=haiku|opus`, `--instance ID`, `--rw`, `--ro`.
