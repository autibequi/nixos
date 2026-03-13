#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/workspace"
TASKS="$WORKSPACE/tasks"
EPHEMERAL="$WORKSPACE/.ephemeral"
LOCKFILE="$EPHEMERAL/.clau.lock"
TASK_TIMEOUT="${CLAU_TIMEOUT:-600}"
SPECIFIC_TASK="${1:-}"
MAX_TASKS="${CLAU_MAX_TASKS:-10}"

mkdir -p "$EPHEMERAL" "$TASKS/running" "$TASKS/done" "$TASKS/failed"

# ── Singleton via flock ──────────────────────────────────────────
exec 200>"$LOCKFILE"
if ! flock -n 200; then
  echo "[clau] Outro worker já rodando. Singleton ativo — saindo."
  exit 0
fi
echo "[clau] Lock adquirido (PID $$)"

# ── Trap: cleanup ao sair — devolve TODAS as tasks órfãs ────────
cleanup() {
  local sig="${1:-EXIT}"
  for dir in "$TASKS/running"/*/; do
    [ -d "$dir" ] || continue
    local name
    name=$(basename "$dir")
    local source
    source=$(grep '^source=' "$dir/.lock" 2>/dev/null | cut -d= -f2 || echo "pending")
    rm -f "$dir/.lock"
    if [ "$source" = "recurring" ]; then
      mv "$dir" "$TASKS/recurring/$name" 2>/dev/null || rm -rf "$dir"
      echo "[clau] $sig — '$name' devolvida pra recurring/"
    else
      mv "$dir" "$TASKS/pending/$name" 2>/dev/null || rm -rf "$dir"
      echo "[clau] $sig — '$name' devolvida pra pending/"
    fi
  done
}
trap 'cleanup SIGINT; exit 1' SIGINT
trap 'cleanup SIGTERM; exit 1' SIGTERM
trap 'cleanup EXIT' EXIT

# ── Reap tasks órfãs em running/ ────────────────────────────────
for dir in "$TASKS/running"/*/; do
  [ -d "$dir" ] || continue
  name=$(basename "$dir")
  if [ -f "$dir/.lock" ]; then
    started=$(grep '^started=' "$dir/.lock" | cut -d= -f2)
    source=$(grep '^source=' "$dir/.lock" | cut -d= -f2 || echo "pending")
    elapsed=$(( $(date +%s) - $(date -d "$started" +%s 2>/dev/null || echo "0") ))
    if [ "$elapsed" -le $(( TASK_TIMEOUT + 300 )) ]; then
      echo "[clau] '$name' ainda dentro do timeout (${elapsed}s) — skip reap"
      continue
    fi
    echo "[clau] Timeout ${elapsed}s — reaping '$name'"
  else
    source="pending"
    echo "[clau] Órfã sem lock — reaping '$name'"
  fi
  rm -f "$dir/.lock"
  if [ "$source" = "recurring" ]; then
    mv "$dir" "$TASKS/recurring/$name" 2>/dev/null || rm -rf "$dir"
    echo "[clau] '$name' → recurring/"
  else
    mv "$dir" "$TASKS/pending/$name" 2>/dev/null || rm -rf "$dir"
    echo "[clau] '$name' → pending/"
  fi
done

# ── Helpers ──────────────────────────────────────────────────────
claim_task() {
  local task="$1" source_dir="$2"
  if [ ! -f "$TASKS/$source_dir/$task/CLAUDE.md" ]; then
    echo "[clau] '$task' sem CLAUDE.md — skip"
    return 1
  fi
  if [ -d "$TASKS/running/$task" ]; then
    echo "[clau] '$task' já em running/ — skip"
    return 1
  fi
  if ! mv "$TASKS/$source_dir/$task" "$TASKS/running/$task" 2>/dev/null; then
    echo "[clau] '$task' sumiu (race condition?) — skip"
    return 1
  fi
  cat > "$TASKS/running/$task/.lock" <<EOF
started=$(date -u +%Y-%m-%dT%H:%M:%SZ)
timeout=$TASK_TIMEOUT
source=$source_dir
pid=$$
EOF
  echo "[clau] ▶ Claimed '$task' ($source_dir)"
  return 0
}

build_task_block() {
  local task="$1" source_dir="$2" is_recurring="$3"
  local context_dir="$EPHEMERAL/notes/$task"
  mkdir -p "$context_dir"

  local instructions context historico recurring_msg
  instructions=$(cat "$TASKS/running/$task/CLAUDE.md")

  context=""
  [ -f "$context_dir/contexto.md" ] && context="
### Contexto da execução anterior
$(cat "$context_dir/contexto.md")"

  historico=""
  [ -f "$context_dir/historico.log" ] && historico="
### Histórico de execuções (últimas 20)
$(tail -20 "$context_dir/historico.log")"

  recurring_msg=""
  if [ "$is_recurring" = "1" ]; then
    recurring_msg="
### Task recorrente (imortal)
- Salve seu estado em: $context_dir/contexto.md
- Use $context_dir/ para arquivos auxiliares
- Não tente fazer tudo de uma vez — priorize, execute o mais importante, salve progresso
- SEMPRE atualize contexto.md no final"
  fi

  cat <<BLOCK
---
## Task: $task
- **Diretório da tarefa:** $TASKS/running/$task
- **Diretório de contexto:** $context_dir
- **Tipo:** $([ "$is_recurring" = "1" ] && echo "RECORRENTE (imortal)" || echo "ONE-SHOT")
- **Source:** $source_dir

$instructions
$recurring_msg
$context
$historico

BLOCK
}

# ── Executar UMA task (chamado diretamente ou como sub-processo) ──
run_single_task() {
  local task="$1" source_dir="$2" is_recurring="$3"
  local block
  block=$(build_task_block "$task" "$source_dir" "$is_recurring")
  local memoria=""
  [ -f "$TASKS/running/$task/memoria.md" ] && memoria="
### Memória evolutiva
$(cat "$TASKS/running/$task/memoria.md")"

  timeout "$TASK_TIMEOUT" claude --permission-mode bypassPermissions --model sonnet \
    -p "Modo autônomo. Tarefa: $task
Hora atual: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Budget: ${TASK_TIMEOUT}s (~10min)

$block
$memoria

## Instruções de execução
1. Siga o protocolo descrito no CLAUDE.md da task
2. Gere o artefato concreto que a task pede
3. Atualize memoria.md em tasks/running/$task/memoria.md com timestamp, o que fez, o que aprendeu, próximos passos
4. Atualize contexto efêmero em $EPHEMERAL/notes/$task/contexto.md
5. Se a task permite auto-evolução, reflita e edite o CLAUDE.md se necessário

## Ao finalizar
$([ "$is_recurring" = "1" ] && echo "- Mova $TASKS/running/$task para $TASKS/recurring/$task" || echo "- Se sucesso: mova $TASKS/running/$task para $TASKS/done/$task")
$([ "$is_recurring" != "1" ] && echo "- Se falha: mova $TASKS/running/$task para $TASKS/failed/$task")
- Registre resultado em $EPHEMERAL/notes/$task/historico.log (formato: TIMESTAMP | ok ou fail | duração)
- Registre uso em $EPHEMERAL/usage/$(date +%Y-%m).jsonl: {\"date\":\"TIMESTAMP\",\"task\":\"$task\",\"duration\":N,\"status\":\"STATUS\",\"type\":\"$([ "$is_recurring" = "1" ] && echo recurring || echo oneshot)\"}
- Resuma em uma linha." 2>&1 || true
}

# ── Task específica: roda só ela e sai ───────────────────────────
if [ -n "$SPECIFIC_TASK" ]; then
  source_dir=""
  is_recurring="0"
  if [ -d "$TASKS/pending/$SPECIFIC_TASK" ]; then
    source_dir="pending"
  elif [ -d "$TASKS/recurring/$SPECIFIC_TASK" ]; then
    source_dir="recurring"
    is_recurring="1"
  else
    echo "[clau] Task '$SPECIFIC_TASK' não encontrada."
    exit 1
  fi

  claim_task "$SPECIFIC_TASK" "$source_dir" || exit 1
  run_single_task "$SPECIFIC_TASK" "$source_dir" "$is_recurring"

  echo "[clau] Done (task específica)."
  exit 0
fi

# ── Coletar tasks: RECORRENTES primeiro, depois PENDING ──────────
task_count=0
MANIFEST=""
TASK_NAMES=()
TASK_SOURCES=()
TASK_RECURRING=()

# 1) Recurring — ordenadas por última execução (mais antiga primeiro)
declare -A recurring_ages
for dir in "$TASKS/recurring"/*/; do
  [ -d "$dir" ] || continue
  name=$(basename "$dir")
  ctx="$EPHEMERAL/notes/$name/historico.log"
  if [ -f "$ctx" ]; then
    last_ts=$(tail -1 "$ctx" | cut -d'|' -f1 | xargs)
    last_epoch=$(date -d "$last_ts" +%s 2>/dev/null || echo "0")
  else
    last_epoch=0
  fi
  recurring_ages[$name]=$last_epoch
done

for task in $(for k in "${!recurring_ages[@]}"; do echo "$k ${recurring_ages[$k]}"; done | sort -k2 -n | cut -d' ' -f1); do
  [ "$task_count" -ge "$MAX_TASKS" ] && break
  claim_task "$task" "recurring" || continue
  MANIFEST+=$(build_task_block "$task" "recurring" "1")
  TASK_NAMES+=("$task")
  TASK_SOURCES+=("recurring")
  TASK_RECURRING+=("1")
  task_count=$((task_count + 1))
done

# 2) Pending (one-shot) — ordem alfabética
for task in $(ls -1 "$TASKS/pending/" 2>/dev/null | grep -v '\.gitkeep' | sort); do
  [ -z "$task" ] && continue
  [ "$task_count" -ge "$MAX_TASKS" ] && break
  claim_task "$task" "pending" || continue
  MANIFEST+=$(build_task_block "$task" "pending" "0")
  TASK_NAMES+=("$task")
  TASK_SOURCES+=("pending")
  TASK_RECURRING+=("0")
  task_count=$((task_count + 1))
done

if [ "$task_count" -eq 0 ]; then
  echo "[clau] Sem tarefas disponíveis."
  exit 0
fi

echo "[clau] $task_count tasks coletadas: ${TASK_NAMES[*]}"
echo "[clau] Lançando Claude sequencial (budget ${TOTAL_TIMEOUT}s)..."

# ── Montar lista de roteamento ───────────────────────────────────
ROUTING=""
for i in "${!TASK_NAMES[@]}"; do
  t="${TASK_NAMES[$i]}"
  s="${TASK_SOURCES[$i]}"
  r="${TASK_RECURRING[$i]}"
  if [ "$r" = "1" ]; then
    ROUTING+="- **${t}** (RECORRENTE): mova tasks/running/${t} → tasks/recurring/${t}
"
  else
    ROUTING+="- **${t}** (ONE-SHOT): sucesso → tasks/done/${t} | falha → tasks/failed/${t}
"
  fi
done

# ── Lançar UM Sonnet sequencial ──────────────────────────────────
start_time=$SECONDS

timeout "$TOTAL_TIMEOUT" claude --permission-mode bypassPermissions --model sonnet \
  -p "Modo autônomo — execução SEQUENCIAL de tasks.
Hora atual: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Budget total: ${TOTAL_TIMEOUT}s (~10min)
Tasks coletadas: $task_count

## INSTRUÇÃO CRÍTICA: EXECUÇÃO SEQUENCIAL COM BUDGET

Você é um executor sequencial. Execute CADA task uma por uma, na ordem listada.
NÃO use sub-agentes. NÃO use a tool Agent. Faça tudo você mesmo, diretamente.

### Regras:
1. Execute as tasks NA ORDEM listada (recorrentes primeiro, depois pending)
2. Para cada task: leia o CLAUDE.md, execute, salve contexto, faça roteamento
3. Seja rápido e objetivo — você tem ~10min para TODAS as tasks
4. Se o tempo estiver acabando, priorize salvar contexto das tasks já feitas
5. Se uma task falhar, registre o erro e passe pra próxima (não trave)
6. Ao terminar cada task, faça o roteamento IMEDIATAMENTE (não deixe pro final)

### Roteamento pós-execução (faça após CADA task):
$ROUTING
- Registre em \`.ephemeral/notes/<task>/historico.log\`: \`TIMESTAMP | ok ou fail | duração\`
- Registre uso em \`.ephemeral/usage/$(date +%Y-%m).jsonl\`: \`{\"date\":\"TIMESTAMP\",\"task\":\"NOME\",\"duration\":N,\"status\":\"STATUS\",\"type\":\"recurring ou oneshot\"}\`

## Tasks (execute nesta ordem):

$MANIFEST" 2>&1 || true

duration=$((SECONDS - start_time))
echo "[clau] Done — executor finalizou em ${duration}s ($task_count tasks)"
