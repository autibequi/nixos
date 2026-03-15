# Fresh Context por Task

> Limpar contexto entre execuções para evitar context rot

## Conceito GSD

> "200k tokens purely for implementation, zero accumulated garbage"

Cada task executa em contexto fresco, sem histórico de tasks anteriores.

## Nossa Abordagem

### Já temos: Worktrees

O `worktree-manager.sh` já isola cada task em worktree separado.

### Precisamos: Limpar Tool Results Cache

Após cada task, limpar cache de tool results:

```bash
# Após finish_task
rm -rf "$CLAUDE_HOME/projects/-workspace/*/tool-results/$task_id"
```

### Precisamos: Fresh prompt por task

O build_task_block já isola o contexto por task. Mas podemos melhorar:

1. **Não incluir histórico global** — apenas contexto da task
2. **Limitar tamanho do bloco** — max 3k tokens por task
3. **Fresh session por task** — cada task = claude --new-session

## Implementação

### Opção 1: Worktree como Fresh Context (Recomendado)

Cada task já roda em worktree via `worktree-manager.sh`. O worktree tem:
- Contexto isolado do projeto
- Não herda tool results de outras tasks

```bash
# No runner, cada task já cria worktree
worker_branch="worker/${CLAU_CLOCK}/${task}"
"$WORKSPACE/scripts/worktree-manager.sh" init "$task" "$worker_branch"
```

### Opção 2: Session reset (avançado)

Adicionar flag `--new-session` ao chamar claude:

```bash
claude --new-session -p "Task: $task..."
```

**Problema:** Não suportado nativamente pelo Claude Code.

### Opção 3: Limpar tool-results

Adicionar no finish_task:

```bash
cleanup_task_cache() {
  local task="$1"
  local cache_dir="$CLAUDE_HOME/projects/-workspace/*/tool-results"
  rm -rf "$cache_dir/$task" 2>/dev/null || true
}
```

## Guidelines Práticos

1. **Keep prompts small** — max 3k tokens por task (seguir size-limits.md)
2. **Use worktrees** — cada task em branch isolada
3. **Limit history** — só últimas 20 mensagens
4. **No cross-task context** — cada task独立
