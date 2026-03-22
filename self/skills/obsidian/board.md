# Board — Regras do Vault

> Fonte unica de verdade para interagir com `/workspace/obsidian/`.

## Mapa do Vault

```
/workspace/obsidian/
|- DASHBOARD.md              Dataview live
|- FEED.md                   RSS (paperboy)
|- trash/                    Lixeira (doctor)
|- tasks/                    Kanban: TODO/ DOING/ DONE/ _archive/
|- inbox/                    Agents → user (feed.md, alertas, cartas)
|- outbox/                   User → hermes
|- projects/                 Trabalho + negocio
|  |- monolito/ bo-container/ front-student/
|  |- search/ accounts/ questions/ ecommerce/
|  |- mortani/ jonathas/
|- vault/                    Conhecimento do sistema
|  |- insights.md            Hub cross-agent (wiseman)
|  |- WISEMAN.md             Grafo do sistema (wiseman)
|  |- templates/agents/      tamagochi, wiseman
|  |- .ephemeral/
|- agents/                   Scheduling + memoria
   |- _schedule/ _running/ _logs/
   |- <nome>/memory.md done/ diarios/
```

## Quem escreve onde

| Pasta | Escreve | Le |
|-------|---------|----|
| `tasks/TODO/` | hermes, user, agentes | runner |
| `inbox/feed.md` | agentes (append) | user |
| `outbox/` | user | hermes |
| `agents/<nome>/memory.md` | proprio agente | proprio |
| `vault/WISEMAN.md` | wiseman | todos |
| `vault/insights.md` | wiseman, qualquer | todos |
| `projects/<nome>/` | coruja, wanderer | todos |

## Tasks

Card: `YYYYMMDD_HH_MM_task-name.md`. Frontmatter: `model`, `timeout`, `mcp`, `agent`. Body: `#stepsN`.

```
outbox/ → hermes → _schedule/ → _running/ → _schedule/ (reagenda)
TODO/ → DOING/ → DONE/ → _archive/ (30d)
```

CLI: `zion agents work` | `zion agents run <nome>` | `zion tasks` | `zion tasks add <titulo>`

## Comunicacao

- `[HH:MM] [nome] msg` → append `inbox/feed.md`
- Alerta: `inbox/ALERTA_<agente>_<tema>.md`
- User → agent: `outbox/para-<nome>-<tema>.md`

## Delegacao

| Tipo | Agent |
|------|-------|
| Saude, disco, limpeza | doctor |
| NixOS, dotfiles, seguranca | mechanic |
| Go/Vue/Nuxt, Jira, PRs | coruja |
| Explorar, sintetizar | wanderer |
| Grafo, weaving, meta | wiseman |
| RSS | paperboy |
| Inbox/outbox, routing | hermes |
| Introspecao, propostas | jafar |
| Monitor repos/PRs | assistant |
| Tasks genericas | tasker |
| Pet virtual | tamagochi |

## Roster (11 ativos)

| Agent | Modelo | Clock |
|-------|--------|-------|
| assistant | haiku | every20 |
| coruja | sonnet | every60 |
| mechanic | sonnet | on demand |
| tamagochi | haiku | every10 |
| tasker | haiku | on demand |
| wanderer | sonnet | every60 |
| hermes | haiku | every10 |
| doctor | haiku | every30 |
| wiseman | sonnet | every60 |
| jafar | sonnet | every120 |
| paperboy | haiku | every60 |

## Escalonamento (quota 7d)

| <50% | 50-70% | 70-85% | >=85% |
|------|--------|--------|-------|
| normal | sonnet every90 | sonnet every120 | sonnet pausado |

Madrugada 21h-6h UTC = livre.
