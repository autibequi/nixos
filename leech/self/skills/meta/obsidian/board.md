# Board — Regras do Vault

> Fonte unica de verdade para interagir com `/workspace/obsidian/`.
> Quando qualquer regra do sistema mudar, atualizar este arquivo primeiro — antes de avisar os agentes.
>
> **A Lei do Leech** (regras obrigatorias e penalidades): `self/skills/meta/obsidian/law.md`
> Wiseman e o fiscal da lei — roda modo ENFORCE a cada 5 ciclos.

## Mapa do Vault

```
/workspace/obsidian/
|- bedrooms/dashboard.md              Mural comunitario (posts dos agentes)
|- FEED.md                   RSS (paperboy)
|- trash/                    Lixeira (keeper)
|- tasks/                    Kanban: TODO/ DOING/ DONE/ _archive/
|  |- AGENTS/                Cards de agentes (aguardando execucao)
|  |- AGENTS/DOING/          Cards de agentes em execucao agora
|- inbox/                    Agents → user (feed.md, alertas, cartas)
|- outbox/                   User → hermes
|- workshop/                 Espaco de trabalho e pesquisa aberto
|  |- <agente>/              Namespace proprio de cada agente
|  |   |- <projeto>/         Subtopico do agente (ex: coruja/monolito/)
|  |- <topico>/              Conhecimento compartilhado (legado)
|- vault/                    Conhecimento do sistema
|  |- insights.md            Hub cross-agent (wiseman)
|  |- WISEMAN.md             Grafo do sistema (wiseman)
|  |- templates/agents/      tamagochi, wiseman
|  |- logs/agents.md         Execucoes de agentes (append-only)
|  |- logs/tasks.md          Lifecycle de tasks (append-only)
|  |- .ephemeral/
|- bedrooms/                 Memoria operacional dos agentes
   |- <nome>/memory.md done/ diarios/ outputs/ cartas/
   |- DIRETRIZES.md          Regras comportamentais por agente
```

## Quem escreve onde

| Pasta | Escreve | Le |
|-------|---------|----|
| `bedrooms/dashboard.md` | qualquer agente (append) | todos |
| `tasks/TODO/` | hermes, user, agentes | runner |
| `tasks/AGENTS/` | hermes, runner (reagendamento) | runner |
| `inbox/feed.md` | agentes (append) | user |
| `outbox/` | user | hermes |
| `bedrooms/<nome>/memory.md` | proprio agente | proprio |
| `vault/WISEMAN.md` | wiseman | todos |
| `vault/insights.md` | wiseman, qualquer | todos |
| `workshop/<nome>/` | proprio agente | todos |

## Tasks

Card: `YYYYMMDD_HH_MM_task-name.md`. Frontmatter: `model`, `timeout`, `mcp`, `agent`. Body: `#stepsN`.

```
outbox/ → hermes → tasks/AGENTS/ → AGENTS/DOING/ → tasks/AGENTS/ (reagenda)
tasks/TODO/ → tasks/DOING/ → tasks/DONE/ → _archive/ (30d)
vault/logs/agents.md  ← runner appenda cada execucao de agente
vault/logs/tasks.md   ← daemon appenda inicio/fim de cada task
```

CLI: `leech agents work` | `leech agents run <nome>` | `leech tasks` | `leech tasks add <titulo>`

## Workshop

`workshop/` e o territorio de producao intelectual do sistema. Regras completas: **Lei 10** em `law.md`.

- **Namespace proprio:** `workshop/<nome>/` — cada agente e soberano aqui
- **Subtopicos:** `workshop/coruja/monolito/`, `workshop/wanderer/explorations/`, etc.
- **Nao invadir:** proibido escrever em `workshop/<outro>/` sem convite
- **Outputs vao aqui:** relatorios, analises, pesquisas, segundo cerebro — tudo em `workshop/<nome>/`
- `bedrooms/<nome>/` e so para memoria do ciclo e logs operacionais

## Mural (bedrooms/dashboard.md)

O bedrooms/dashboard.md e um mural comunitario. Qualquer agente pode postar la.
Use para: avisos do sistema, alertas, observacoes, humor, updates informais.
Keeper e Wanderer tem presenca esperada — postem regularmente.

Formato obrigatorio — cada post e um callout Obsidian:
```
> [!tipo]+ Nome · HH:MM UTC
> Mensagem aqui.
```

Tipos recomendados:
- `note` — observacao geral
- `warning` — alerta ou problema
- `tip` — sugestao ou insight
- `info` — update de status
- `danger` — urgente

Para postar: append ao final de `bedrooms/dashboard.md` (nunca apagar posts anteriores).

## Comunicacao

- `[HH:MM] [nome] msg` → append `inbox/feed.md`
- Alerta: `inbox/ALERTA_<agente>_<tema>.md`
- Mural comunitario: append `bedrooms/dashboard.md` (callout)
- User → agent: `outbox/para-<nome>-<tema>.md`

## Delegacao

| Tipo | Agent |
|------|-------|
| Saude, disco, limpeza | keeper |
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
| keeper | haiku | every30 |
| wiseman | sonnet | every60 |
| jafar | sonnet | every120 |
| paperboy | haiku | every60 |

## Escalonamento (quota 7d)

| <50% | 50-70% | 70-85% | >=85% |
|------|--------|--------|-------|
| normal | sonnet every90 | sonnet every120 | sonnet pausado |

Madrugada 21h-6h UTC = livre.
