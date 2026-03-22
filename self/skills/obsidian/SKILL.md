# Skill: Obsidian

> Gestao completa do vault em `/workspace/obsidian/` — estrutura, tasks, dashboard, graph view, agentes.
> **Regras no sistema Zion (ler antes de interagir com obsidian):**
> - `/workspace/self/system/BOARDRULES.md` — regras, mapa, roster (qualquer interacao com /obsidian/)
> - `/workspace/self/system/BREAKROOMRULES.md` — protocolo de agents (interacao com /obsidian/agents/)

---

## Estrutura do Vault (v5.0)

```
/workspace/obsidian/
|- BOARDRULES.md             FONTE UNICA DE VERDADE (regras, roster, protocolo)
|- DASHBOARD.md              Dashboard central (Dataview live)
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
|- outbox/                   Items do user -> hermes refina -> TODO/
|
|- projects/                 Projetos (trabalho + negocio) — NAO e vault
|  |- monolito/              overview, patterns, hotspots, pulse
|  |- bo-container/
|  |- front-student/
|  |- search/, accounts/, questions/, ecommerce/
|  |- mortani/               Metricas de desenvolvimento
|  |- jonathas/              Plano de negocio
|
|- vault/                    Base de conhecimento do SISTEMA
|  |- insights.md            Hub de insights cross-agent (wiseman cuida)
|  |- WISEMAN.md             Grafo do sistema (wiseman atualiza a cada meta-ciclo)
|  |- templates/             Templates Obsidian
|  |  |- agents/             So agentes ativos: tamagochi.md, wiseman.md
|  |- .ephemeral/            Cache + cron-logs (hidden)
|
|- agents/                   Memoria e cards dos agentes
   |- BREAKROOMRULES.md      Protocolo interno
   |- _schedule/             Cards agendados
   |- _running/              Cards em execucao
   |- _logs/                 Logs de atividade
   |- <nome>/
      |- memory.md           Memoria persistente
      |- done/               Cards concluidos
      |- diarios/            Diarios pessoais
```

---

## Sistema de Tasks

### Formato de card

```
YYYYMMDD_HH_MM_task-name.md
```

### Frontmatter obrigatorio

```yaml
---
model: haiku        # haiku | sonnet
timeout: 300        # segundos
mcp: false
agent: nome         # agente responsavel
---
```

Tags no body: `#stepsN` controla max_turns.

### Ciclo de vida

```
outbox/ -> hermes cria card em TODO/
TODO/ -> runner move para DOING/ quando hora chega
DOING/ -> DONE/ (runner) ou TODO/ (reschedule pelo agente)
DONE/ -> _archive/ (doctor, 30 dias)
```

### Comandos CLI

| Comando | O que faz |
|---------|-----------|
| `zion agents work` | Executa todos os cards vencidos em _schedule/ |
| `zion agents run <nome>` | Executa agente imediatamente |
| `zion tasks` | Lista TODO/DOING/DONE |
| `zion tasks add <titulo>` | Cria task em TODO/ |
| `zion tasks run <nome>` | Executa task especifica |

---

## Grafo do Obsidian (Ctrl+G)

### Como funciona

O grafo do Obsidian renderiza conexoes entre notas baseado em:
1. **Wikilinks no corpo:** `[[nome-da-nota]]` ou `[[nome-da-nota|texto]]`
2. **Campo `related:` no frontmatter** (array de wikilinks)
3. **Tags** — nao criam edges mas agrupam visualmente por cor

### Configurar nota como hub (no grafo)

```yaml
---
tags: [sistema, meta, infraestrutura]
related:
  - "[[BOARDRULES]]"
  - "[[DASHBOARD]]"
  - "[[vault/insights]]"
  - "[[vault/WISEMAN]]"
---
```

### Abrir grafo no startup (workspace.json)

Para o grafo abrir como janela principal, `workspace.json` deve ter:

```json
{
  "main": {
    "type": "split",
    "children": [
      {
        "type": "tabs",
        "children": [
          {
            "type": "leaf",
            "state": {
              "type": "graph",
              "state": {}
            }
          }
        ]
      }
    ]
  }
}
```

**ATENCAO:** Obsidian sobrescreve `workspace.json` ao fechar. So editar com Obsidian FECHADO.
Path: `/workspace/obsidian/.obsidian/workspace.json`

### Manter grafo organizado (responsabilidade do wiseman)

Wiseman deve, a cada ciclo de grafo:
1. Ler arquivos novos em `vault/`, `projects/`, `agents/*/memory.md`
2. Adicionar frontmatter com `tags` + `related` a notas sem conexao
3. Verificar links quebrados (pasta movida, arquivo renomeado)
4. Garantir que hubs (BOARDRULES, WISEMAN.md, insights.md, DASHBOARD) tenham backlinks das notas filha
5. Atualizar `vault/WISEMAN.md` com estado atual do grafo

### Padroes de conexao

| Tipo | Como fazer |
|------|-----------|
| Nota filha → hub | `related: ["[[BOARDRULES]]"]` no frontmatter |
| Hub → hub | `related:` bidirecional entre WISEMAN, insights, BOARDRULES |
| Cluster tematico | mesma tag em todas as notas do cluster |
| Nota nova sem conexao | adicionar 2-3 `related` relevantes |

### Notas que sao hubs (muitos edges)

- `BOARDRULES.md` — regras, estrutura, roster
- `vault/WISEMAN.md` — grafo do sistema, meta-analise
- `vault/insights.md` — insights cross-agent
- `DASHBOARD.md` — ponto de entrada visual

### Boas praticas

- Nao criar backlinks por completude — so se a conexao for semanticamente real
- Prefer `related:` no frontmatter a wikilinks espalhados no corpo
- Tags sao para agrupamento visual, nao para navegacao
- Notas sem nenhum `related` ficam isoladas no grafo — adicionar pelo menos 1 link ao hub mais proximo

---

## Paths Importantes

| O que | Path |
|-------|------|
| Fonte de verdade | `BOARDRULES.md` |
| Grafo do sistema | `vault/WISEMAN.md` |
| Hub de insights | `vault/insights.md` |
| Dashboard | `DASHBOARD.md` |
| Feed agentes | `inbox/feed.md` |
| Alertas urgentes | `inbox/ALERTA_<agente>_<tema>.md` |
| Memoria de agente | `agents/<nome>/memory.md` |
| Workspace Obsidian | `.obsidian/workspace.json` |
| Cache RSS | `.ephemeral/rss/` |

---

## Fluxo inbox/outbox

### inbox (agente → user)

Agentes fazem append em `inbox/feed.md`:
```
[02:10] [wiseman] mensagem
```
Alertas urgentes: `inbox/ALERTA_<agente>_<tema>.md`

### outbox (user → hermes)

User cria `.md` em `outbox/`. Hermes le, refina, cria card em `agents/_schedule/`.

---

## DASHBOARD.md

Usa DataviewJS e Dataview para queries ao vivo.

### Contar cards

```javascript
const todo   = dv.pages('"tasks/TODO"').length
const doing  = dv.pages('"tasks/DOING"').length
const done   = dv.pages('"tasks/DONE"').length
```

### Tabela de cards

```dataview
TABLE WITHOUT ID
  file.name as "Card",
  agent as "Agente",
  model as "Modelo"
FROM "tasks/DOING"
SORT file.mtime DESC
```

### Tabela de agentes (memories)

```dataviewjs
const agents = ["assistant","coruja","doctor","hermes","jafar","mechanic","paperboy","tamagochi","tasker","wanderer","wiseman"]
let rows = []
for (const a of agents) {
  const mem = dv.page(`agents/${a}/memory`)
  rows.push([a, mem ? mem.file.mtime : "sem memoria"])
}
dv.table(["Agent", "Ultima Atualizacao"], rows)
```

---

## Callouts

```markdown
> [!warning]+ Colapsado por padrao
> [!info]- Expandido por padrao
```

| Secao | Tipo |
|-------|------|
| Alertas | `[!warning]` |
| Info | `[!info]` |
| Em Andamento | `[!example]` |
| TODO | `[!tip]` |
| Concluidos | `[!success]` |
| Agentes | `[!abstract]` |
| Feed | `[!quote]` |

---

## Plugins instalados

| Plugin | Uso |
|--------|-----|
| **Dataview** | Queries SQL-like + DataviewJS em notas |
| **Calendar** | Visualizacao de notas por data |
