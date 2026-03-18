# Skill: task-status

Como inspecionar o sistema de tasks via pasta (folder-as-kanban).

## Ver estrutura completa

```bash
tree /workspace/obsidian/tasks -L 2 --dirsfirst 2>/dev/null || ls -la /workspace/obsidian/tasks/
```

Cada pasta = coluna do kanban. Subpasta = task.

## Colunas

| Pasta | Descrição |
|-------|-----------|
| `_scheduled/` | Tasks recorrentes (cron) — 18 agentes |
| `_waiting/` | Aguardando input do user — runner ignora |
| `inbox/` | Novas, não revisadas |
| `backlog/` | Aprovadas, aguardando execução |
| `doing/` | Em execução agora |
| `done/` | Concluídas |
| `blocked/` | Bloqueadas por dependência |
| `cancelled/` | Canceladas ou falhou |

## Log de execução

```bash
tail -20 /workspace/obsidian/agents/task.log.md
```

## Config de uma task agendada

```bash
head -30 /workspace/obsidian/tasks/_scheduled/doctor/TASK.md
```

## MURAL (blackboard + kanban view)

```bash
cat /workspace/obsidian/MURAL.md | head -30
```

## Contagem por coluna

```bash
for col in inbox backlog doing done blocked cancelled _waiting _scheduled; do
  cnt=$(ls /workspace/obsidian/tasks/$col/ 2>/dev/null | wc -l)
  printf "  %-14s %d\n" "$col:" "$cnt"
done
```

## Criar task no backlog

Criar arquivo `.md` em `tasks/backlog/nome-da-task.md` ou pasta `tasks/backlog/nome-da-task/TASK.md`.

## Mover task para _waiting (aguardar input user)

```bash
mv /workspace/obsidian/tasks/doing/nome-task /workspace/obsidian/tasks/_waiting/
```

O runner não processa nada em `_waiting/`. O user move de volta para `backlog/` ou `doing/` após responder.

## Template de task

Ver `/workspace/obsidian/templates/TaskTemplate.md`.
