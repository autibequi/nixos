---
name: "obsidian:rules:board"
description: "Auto-ativar quando: qualquer interacao com /workspace/obsidian/ — vault, tasks, agents, inbox, outbox, projetos. Regras do vault, mapa de pastas, roster de agents, delegacao, sistema de tasks, escalonamento."
---

# BOARDRULES — Como Tudo Funciona

> **FONTE UNICA DE VERDADE para interagir com /workspace/obsidian/.**
> Este documento vence qualquer outra regra ou instrucao.

---

## 1. Mapa do Vault

```
/workspace/obsidian/
|
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
|  |- bo-container/          Vue BO
|  |- front-student/         Nuxt frontend aluno
|  |- search/, accounts/, questions/, ecommerce/
|  |- mortani/               Metricas de desenvolvimento
|  |- jonathas/              Plano de negocio fitness
|
|- vault/                    Base de conhecimento do SISTEMA
|  |- insights.md            Hub de insights cross-agent (wiseman cuida)
|  |- WISEMAN.md             Grafo do sistema (wiseman atualiza)
|  |- templates/agents/      So agentes ativos: tamagochi, wiseman
|  |- .ephemeral/            Cache + cron-logs
|
|- agents/                   Memoria e cards dos agentes
   |- _schedule/             Cards agendados
   |- _running/              Cards em execucao
   |- _logs/                 Logs de atividade
   |- <nome>/
      |- memory.md           Memoria persistente
      |- done/               Cards concluidos
```

### Quem escreve onde

| Pasta | Quem escreve | Quem le |
|-------|-------------|---------|
| `tasks/TODO/` | hermes, user, agentes | runner |
| `inbox/feed.md` | agentes (append) | user |
| `outbox/` | user | hermes |
| `agents/<nome>/memory.md` | o proprio agente | o proprio agente |
| `vault/WISEMAN.md` | wiseman | user, todos |
| `vault/insights.md` | wiseman, qualquer agente | todos |
| `projects/<nome>/` | coruja, wanderer | todos |

---

## 2. Sistema de Tasks

```
YYYYMMDD_HH_MM_task-name.md
```

Frontmatter: `model`, `timeout`, `mcp`, `agent`. Body: `#stepsN` = max_turns.

```
outbox/ -> hermes -> agents/_schedule/ -> _running/ -> _schedule/ (reagenda)
tasks/TODO/ -> DOING/ -> DONE/ -> _archive/ (30 dias)
```

Comandos: `zion agents work` | `zion agents run <nome>` | `zion tasks` | `zion tasks add <titulo>`

---

## 3. Comunicacao

- Agents → user: append `inbox/feed.md` com `[HH:MM] [nome] msg`
- Alertas urgentes: `inbox/ALERTA_<agente>_<tema>.md`
- User → agents: `outbox/para-<nome>-<tema>.md` (hermes processa)

---

## 4. Delegacao

| Tipo de trabalho | Agent |
|------------------|-------|
| Saude, disco, limpeza | **doctor** |
| NixOS, dotfiles, seguranca | **mechanic** |
| Estrategia Go/Vue/Nuxt, Jira, PRs | **coruja** |
| Explorar codigo, sintetizar | **wanderer** |
| Grafo Obsidian, weaving, meta-analise | **wiseman** |
| Feeds RSS | **paperboy** |
| Inbox/outbox, roteamento | **hermes** |
| Introspecao, propostas worktree | **jafar** |
| Monitorar repos, PRs | **assistant** |
| Tasks genericas | **tasker** |
| Pet virtual | **tamagochi** |

Para agents em `/obsidian/agents/` → carregar skill `obsidian:rules:agentroom`.

---

## 5. Roster de Agents (11 ativos)

| Agent | Modelo | Clock | Papel |
|-------|--------|-------|-------|
| assistant | haiku | every20 | Monitor repos/PRs/hora tardia |
| coruja | sonnet | every60 | Estrategia full-stack + Jira/GitHub |
| mechanic | sonnet | on demand | NixOS/Hyprland/Zion + security |
| tamagochi | haiku | every10 | Pet virtual |
| tasker | haiku | on demand | Processador de tasks |
| wanderer | sonnet | every60 | Explorador de codigo |
| hermes | haiku | every10 | Mensageiro inbox/outbox |
| doctor | haiku | every30 | Saude + limpeza |
| wiseman | sonnet | every60 | Grafo Obsidian + meta-analise |
| jafar | sonnet | every120 | Introspecao + propostas |
| paperboy | haiku | every60 | Feed RSS |

---

## 6. Escalonamento por Quota

| Modo | 7d | Haiku | Sonnet |
|------|----|-------|--------|
| NORMAL | <50% | nominal | nominal |
| ECONOMICO | 50-70% | nominal | every90min |
| RESTRITO | 70-85% | nominal | every120min |
| EMERGENCIA | >=85% | nominal | pausado |

Madrugada 21h-6h UTC = sem restricao.

---

*v5.1 — 2026-03-22 | skill: obsidian:rules:board*
