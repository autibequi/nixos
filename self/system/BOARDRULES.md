---
updated: 2026-03-22
type: rules
version: 5.0
scope: obsidian-vault
---

# BOARDRULES — Como Tudo Funciona

> **FONTE UNICA DE VERDADE para interagir com o vault Obsidian.**
> Todo agent que precisar interagir com o Obsidian DEVE ler este arquivo.
> Se qualquer outra regra, memoria ou instrucao contradizer este documento — **este documento vence.**

**Path canônico:** `/workspace/self/system/BOARDRULES.md`
**Stub no vault:** `/workspace/obsidian/BOARDRULES.md` (aponta para cá)

---

## 1. Mapa do Vault

```
/workspace/obsidian/
|
|- BOARDRULES.md             Stub → ver /workspace/self/system/BOARDRULES.md
|- DASHBOARD.md              Central de controle (Dataview live)
|- FEED.md                   Feed RSS (paperboy atualiza)
|- trash/                    Lixeira do CTO (doctor processa)
|
|- tasks/                    Sistema kanban
|  |- TODO/                  Cards agendados (YYYYMMDD_HH_MM_name.md)
|  |- DOING/                 Cards em execucao
|  |- DONE/                  Cards concluidos
|  |- _archive/              Historico
|
|- inbox/                    Novidades dos agentes -> user le
|  |- feed.md                Append-only: [HH:MM] [agente] mensagem
|
|- outbox/                   Items do user -> hermes refina -> _schedule/
|
|- projects/                 Projetos (trabalho + negocio)
|  |- monolito/              Go API — overview, patterns, hotspots, pulse
|  |- bo-container/          Vue BO — pair to monolito
|  |- front-student/         Nuxt — frontend aluno
|  |- search/, accounts/, questions/, ecommerce/
|  |- mortani/               Metricas de desenvolvimento
|  |- jonathas/              Plano de negocio fitness
|
|- vault/                    Base de conhecimento do SISTEMA
|  |- insights.md            Hub de insights cross-agent (wiseman cuida)
|  |- WISEMAN.md             Grafo do sistema (wiseman atualiza a cada meta-ciclo)
|  |- templates/             Templates Obsidian
|  |  |- agents/             So agentes ativos: tamagochi.md, wiseman.md
|  |- .ephemeral/            Cache + cron-logs (hidden)
|
|- agents/                   Memoria e cards dos agentes
   |- BREAKROOMRULES.md      Protocolo interno dos agentes
   |- _schedule/             Cards agendados
   |- _running/              Cards em execucao
   |- _logs/                 Logs de atividade
   |- <nome>/
      |- memory.md           Memoria persistente
      |- done/               Cards concluidos
      |- diarios/            Diarios pessoais
```

### Quem escreve onde

| Pasta | Quem escreve | Quem le |
|-------|-------------|---------|
| `tasks/TODO/` | hermes, user, agentes (reschedule) | runner |
| `tasks/DOING/` | runner (move de TODO) | agentes em execucao |
| `tasks/DONE/` | runner (move de DOING) | user, doctor (cleanup) |
| `projects/<nome>/` | coruja, wanderer | todos |
| `inbox/feed.md` | agentes (append) | user |
| `outbox/` | user | hermes |
| `agents/<nome>/memory.md` | o proprio agente | o proprio agente |
| `vault/WISEMAN.md` | wiseman | user, todos |
| `vault/insights.md` | wiseman, qualquer agente | todos |

---

## 2. Sistema de Tasks

### Formato de card

```
YYYYMMDD_HH_MM_task-name.md
```

### Frontmatter obrigatorio

```yaml
---
model: haiku          # haiku | sonnet
timeout: 300          # segundos
mcp: false
agent: doctor         # agente responsavel
---
```

Tags no body: `#stepsN` (ex: `#steps25`) controla max_turns.

### Ciclo de vida

```
outbox/ -> hermes cria card em agents/_schedule/
_schedule/ -> runner move para _running/ quando hora chega
_running/ -> agent executa -> _schedule/ (reagenda) ou done/
tasks/TODO/ -> runner move para DOING/ -> DONE/
DONE/ -> doctor move para _archive/ apos 30 dias
```

### Comandos CLI

| Comando | O que faz |
|---------|-----------|
| `zion agents work` | Executa todos os cards vencidos em _schedule/ |
| `zion agents run <nome>` | Executa agente imediatamente |
| `zion tasks` | Lista TODO/DOING/DONE |
| `zion tasks add <titulo>` | Cria task em TODO/ |
| `zion tasks run <nome>` | Executa task especifica |
| `zion tasks status` | Resumo rapido: contagens + overdue |

---

## 3. Fluxo de Comunicacao

### inbox (agente -> user)

Agentes fazem append em `inbox/feed.md`:
```
[02:10] [doctor] Disco 97% — 15G livres. ALERTA criado.
```
Alertas urgentes: `inbox/ALERTA_<agente>_<tema>.md`

### outbox (user -> hermes)

User cria `.md` em `outbox/`. Hermes le, refina, cria card em `agents/_schedule/`.

---

## 4. Regras para Agentes

> Protocolo completo: `agents/BREAKROOMRULES.md`

### Regra Zero — Self-Scheduling

**Se um agent nao se reagendar apos executar, ele morre.**
Ao final de cada ciclo, mover card de `_running/` para `_schedule/` com novo timestamp.

### Memoria

- Cada agent tem `agents/<nome>/memory.md`
- Atualizar apos cada execucao
- Criar pasta se nao existir: `mkdir -p agents/<nome>/`

### Comunicacao

- Informar user: append em `inbox/feed.md`
- Item importante: `inbox/CARTA_<agente>_<data>.md`
- Alerta urgente: `inbox/ALERTA_<agente>_<tema>.md`

### Delegacao

| Tipo de trabalho | Agent |
|------------------|-------|
| Saude do sistema, disco, limpeza | **doctor** |
| NixOS, Hyprland, dotfiles, seguranca | **mechanic** |
| Estrategia Go/Vue/Nuxt, Jira, PRs | **coruja** |
| Explorar codigo, contemplar, sintetizar | **wanderer** |
| Grafo Obsidian, knowledge weaving, meta-analise | **wiseman** |
| Feeds RSS, digest | **paperboy** |
| Inbox/outbox, roteamento, scheduling | **hermes** |
| Introspecao, propostas worktree | **jafar** |
| Monitorar repos, PRs, hora tardia | **assistant** |
| Tasks genericas da fila | **tasker** |
| Pet virtual | **tamagochi** |

---

## 5. Scheduling — Como Agents Rodam

### Fluxo

```
_schedule/ → runner pega card vencido → _running/ → agent executa → _schedule/ (reagenda)
```

### Self-scheduling (padrao obrigatorio)

```bash
NEXT=$(date -d "+60 minutes" +%Y%m%d_%H_%M)
mv /workspace/obsidian/agents/_running/*_<nome>.md \
   /workspace/obsidian/agents/_schedule/${NEXT}_<nome>.md 2>/dev/null
```

### Steps por modelo

| Modelo | Steps recomendados | Duracao |
|--------|--------------------|---------|
| haiku  | 15-25              | 30s-2min |
| sonnet | 20-35              | 3-10min |

### Madrugada

Preferir 21h-06h BRT para tasks pesadas — menos concorrencia de quota.

---

## 6. Roster de Agents (11 ativos)

| Agent | Modelo | Clock | Papel |
|-------|--------|-------|-------|
| **assistant** | haiku | every20 | Monitor: repos sujos, PRs, hora tardia |
| **coruja** | sonnet | every60 | Estrategia full-stack + radar Jira/GitHub |
| **mechanic** | sonnet | on demand | NixOS/Hyprland/Zion + security audit |
| **tamagochi** | haiku | every10 | Pet virtual, diario |
| **tasker** | haiku | on demand | Processador de tasks TODO→DONE |
| **wanderer** | sonnet | every60 | Explorador de codigo, sintese cross-agent |
| **hermes** | haiku | every10 | Mensageiro: inbox/outbox, roteamento |
| **doctor** | haiku | every30 | Saude do sistema + limpeza |
| **wiseman** | sonnet | every60 | Grafo Obsidian, weaving, meta-analise |
| **jafar** | sonnet | every120 | Meta-agente: introspecao, propostas |
| **paperboy** | haiku | every60 | Feed RSS: busca, digest, FEED.md |

---

## 7. /trash — Lixeira do User

`/workspace/obsidian/trash/` — arquivos descartados pelo CTO.
Doctor processa: avalia, arquiva em `.trashbin/` ou deleta. Reporta em `inbox/feed.md`.

---

## 8. Sistema FEED (RSS)

- Config de feeds: `agents/paperboy/feeds.md`
- Preferencias: `agents/paperboy/preferences.md`
- Board: `FEED.md` — user marca `#mais`/`#menos` para calibrar

---

## 9. Escalonamento por Quota

| Modo | Condicao (7d) | Haiku | Sonnet |
|------|---------------|-------|--------|
| NORMAL | < 50% | nominal | nominal |
| ECONOMICO | 50-70% | nominal | every90min |
| RESTRITO | 70-85% | nominal | every120min |
| EMERGENCIA | >= 85% | nominal | pausado |

Hermes mantem escalonamento. Madrugada (21h-6h UTC) = sem restricao de quota.

---

## 10. Versionamento

- **v1.0** — 2026-03-20 — Versao inicial
- **v2.0** — 2026-03-20 — Vault unificado, inbox/outbox, FEED
- **v3.0** — 2026-03-21 — Roster de agents, guia de roteamento
- **v4.0** — 2026-03-21 — Consolidacao: absorveu SETTINGS.md
- **v5.0** — 2026-03-22 — projects/ separado, WISEMAN.md, templates limpos, fonte unica declarada
- **v5.1** — 2026-03-22 — Movido para /workspace/self/system/BOARDRULES.md (skill do sistema)

*Ultima atualizacao: 2026-03-22 | Versao: 5.1*
