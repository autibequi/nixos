# Execução em Waves

> Paralelizar tasks independentes

## Conceito

Agrupar tasks em "waves" baseadas em dependências:
- **Mesma wave**: executam em paralelo
- **Wave sequencial**: espera a anterior terminar

## Task Dependencies

No frontmatter da task, especificar dependências:

```yaml
---
name: task-name
wave: 1
depends_on: []
---

# ou

---
name: task-name  
wave: 2
depends_on:
  - task-outra-1
  - task-outra-2
---
```

## Exemplo de Execução

```
WAVE 1 (parallel)
┌─────────┐ ┌─────────┐
│ Plan 01 │ │ Plan 02 │  → executam juntos
└─────────┘ └─────────┘

WAVE 2 (parallel)
┌─────────┐ ┌─────────┐
│ Plan 03 │ │ Plan 04 │  → esperam WAVE 1
└─────────┘ └─────────┘
```

## Workflow

1. **Planejador** define waves e dependências
2. **Runner** detecta dependências e agrupa
3. **Executor** roda cada wave:
   - Tasks na mesma wave → paralelo (xargs -P)
   - Waves → sequencial

## Implementação no Runner

```bash
# Pseudo-code
get_waves() {
  # 1. Ler todas tasks
  # 2. Ler depends_on de cada
  # 3. Topological sort
  # 4. Agrupar em waves
}

execute_waves() {
  for wave in $(get_waves); do
    parallel_tasks $wave  # xargs -P
  done
}
```
