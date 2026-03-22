# Skill: Obsidian

> Gestao do vault Obsidian em `/workspace/obsidian/` -- tasks, dashboards, Dataview e agentes.

---

## Estrutura do Vault

```
/workspace/obsidian/
|- DASHBOARD.md              Dashboard central (Dataview)
|- SETTINGS.md               Documento central (como tudo funciona + roster + protocolo)
|- TAMAGOCHI.md              Pet virtual
|- FEED.md                   Feed RSS atualizado
|- FEED.config.md            Lista de feeds RSS
|- trash/                    Lixeira do CTO (trashman processa)
|
|- tasks/                    Sistema kanban
|  |- TODO/                  Cards agendados (YYYYMMDD_HH_MM_name.md)
|  |- DOING/                 Cards em execucao
|  |- DONE/                  Cards concluidos
|  |- _archive/              Historico + _scheduled/
|
|- inbox/                    Novidades dos agentes -> user le
|  |- feed.md                Append-only: [HH:MM] [agente] mensagem
|
|- outbox/                   Items do user -> scheduler refina -> TODO/
|
|- vault/                    Base de conhecimento
   |- agents/<nome>/         Pasta por agente (memory.md, diarios/, outputs/)
   |- tasks/_archive/_scheduled/<agente>/  TASK.md + memoria.md por agente
   |- chrome/                Drawings
   |- explorations/          Pesquisas
   |- inspections/           Inspecoes
   |- templates/             Templates Obsidian
   |- insights.md            Hub de insights
   |- sugestoes/             Sugestoes
   |- trash/                 Lixeira interna reversivel
   |- .ephemeral/            Cache + cron-logs
```

---

## Sistema de Tasks

### Formato de card

```
YYYYMMDD_HH_MM_task-name.md
```

### Frontmatter

```yaml
---
model: haiku
timeout: 300
mcp: false
agent: nome-do-agente
---
```

Tags no body: `#stepsN` controla max_turns.

### Ciclo de vida

```
outbox/ -> scheduler cria card em TODO/
TODO/ -> runner move para DOING/ quando hora chega
DOING/ -> DONE/ (runner) ou TODO/ (reschedule pelo agente)
DONE/ -> _archive/ (trashman, 30 dias)
```

### Comandos CLI

| Comando | O que faz |
|---------|-----------|
| `zion tasks list` | Lista TODO/ e DOING/ |
| `zion tasks list --all` | Inclui DONE/ |
| `zion tasks list --log` | Mostra cron logs |
| `zion tasks run <nome>` | Executa card por nome |
| `zion tasks new <nome>` | Cria card em TODO/ |
| `zion tasks tick` | Executa cards vencidos |
| `zion tasks tick --dry-run` | Mostra o que seria executado |

---

## Paths Importantes

| O que | Path |
|-------|------|
| Regras e roster | `SETTINGS.md` (raiz) |
| Dashboard | `DASHBOARD.md` (raiz) |
| Lixeira do CTO | `trash/` (raiz) |
| TASK.md de agente | `vault/tasks/_archive/_scheduled/<nome>/TASK.md` |
| Memoria do agente | `vault/agents/<nome>/memory.md` |
| Outputs do agente | `vault/agents/<nome>/outputs/` |
| Artefatos de task | `vault/tasks/<slug>/` |
| Cron logs | `vault/.ephemeral/cron-logs/<nome>/` |
| Heartbeat | `vault/.ephemeral/heartbeat` |
| Feed RSS | `FEED.md` (raiz) |
| Config RSS | `FEED.config.md` (raiz) |
| Inbox (agentes) | `inbox/feed.md` |
| Outbox (user) | `outbox/` |

---

## Fluxo inbox/outbox

### inbox (agente -> user)

Agentes fazem append em `inbox/feed.md`:
```
[14:00] [trashman] Limpeza: 3 arquivos
```
Alertas urgentes: criar `inbox/ALERTA_<agente>_<tema>.md`

### outbox (user -> scheduler)

User cria `.md` em `outbox/`. Scheduler le, refina, cria card em TODO/.

---

## DASHBOARD.md -- Dashboard

Usa DataviewJS para stats e Dataview para tabelas:

### Stats com DataviewJS

```javascript
const todo = dv.pages('"contractors/_schedule"').length
const doing = dv.pages('"tasks/DOING"').length
```

### Tabelas de cards

```dataview
TABLE WITHOUT ID
  file.name as "Card",
  agent as "Agente",
  model as "Modelo"
FROM "tasks/DOING"
SORT file.mtime DESC
```

### Tabela de agentes

```dataview
TABLE WITHOUT ID
  regexreplace(file.folder, ".*/", "") as "Agente",
  file.mtime as "Atualizado"
FROM "vault/agents"
WHERE file.name = "memory"
```

---

## Sistema FEED (RSS)

### FEED.config.md

Define feeds a buscar:
```
| Feed | URL | Frequencia | Tags |
```

### FEED.md

Board com items + digest curado. Task `paperboy` atualiza periodicamente.
Cache em `vault/.ephemeral/rss/`.

---

## Callouts Obsidian

```markdown
> [!tipo]+ Expandido
> [!tipo]- Colapsado
```

| Secao | Tipo | Cor |
|-------|------|-----|
| Em Andamento | `[!example]` | roxo |
| TODO | `[!tip]` | verde |
| Outbox | `[!todo]` | azul claro |
| DONE | `[!success]` | verde escuro |
| Agentes | `[!abstract]` | ciano |
| Notas | `[!question]` | laranja |

---

## Operacoes Comuns

### Mover para trash
```bash
mv /workspace/obsidian/<arquivo> /workspace/obsidian/vault/trash/
```

### Criar task
```bash
zion tasks new minha-task --model haiku --agent nome
```

### Ver logs de execucao
```bash
zion tasks list --log
```

---

## Plugins (assumidos instalados)

| Plugin | Uso |
|--------|-----|
| **Dataview** | Queries SQL-like + DataviewJS |
| **Admonitions** | Callouts visuais (sintaxe nativa) |
