#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/workspace"
TASKS="$WORKSPACE/vault/_agent/tasks"
EPHEMERAL="$WORKSPACE/.ephemeral"
LOCKFILE="$EPHEMERAL/.clau.lock"
CLAU_VERBOSE="${CLAU_VERBOSE:-0}"
SPECIFIC_TASK="${1:-}"
MAX_TASKS="${CLAU_MAX_TASKS:-5}"
MAX_PARALLEL="${CLAU_MAX_PARALLEL:-1}"
NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=1536}"
export NODE_OPTIONS

# Defaults (overridden by frontmatter)
DEFAULT_TIMEOUT_RECURRING=300
DEFAULT_TIMEOUT_PENDING=900
DEFAULT_MODEL_RECURRING="haiku"
DEFAULT_MODEL_PENDING="sonnet"
DEFAULT_SCHEDULE="night"
DEFAULT_MAX_TURNS=25

mkdir -p "$EPHEMERAL" "$TASKS/running" "$TASKS/done" "$TASKS/failed" "$WORKSPACE/vault/sugestoes" "$WORKSPACE/vault/_agent/reports"

# Ensure no-mcp config exists
[ -f "$EPHEMERAL/no-mcp.json" ] || echo '{"mcpServers":{}}' > "$EPHEMERAL/no-mcp.json"

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
    if [ "$elapsed" -le 1200 ]; then
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

# ── Frontmatter parser ───────────────────────────────────────────
parse_frontmatter() {
  local file="$1" key="$2"
  [ -f "$file" ] || return
  # Read between first two --- lines, find key, extract value (no sed needed)
  local in_fm=0 line
  while IFS= read -r line; do
    if [ "$line" = "---" ]; then
      if [ "$in_fm" = "1" ]; then break; fi
      in_fm=1
      continue
    fi
    if [ "$in_fm" = "1" ]; then
      case "$line" in
        "${key}:"*)
          echo "${line#*: }" | tr -d '[:space:]'
          return
          ;;
      esac
    fi
  done < "$file"
}

# ── Scheduling: day/night ────────────────────────────────────────
is_daytime() {
  local hour
  hour=$(date +%H)
  [ "$hour" -ge 7 ] && [ "$hour" -le 23 ]
}

should_run_task() {
  local task_dir="$1" source="$2"
  # Pending tasks always run (user created them to execute)
  [ "$source" = "pending" ] && return 0
  local schedule
  schedule=$(parse_frontmatter "$task_dir/CLAUDE.md" "schedule")
  schedule=${schedule:-$DEFAULT_SCHEDULE}
  [ "$schedule" = "always" ] && return 0
  ! is_daytime && return 0
  return 1  # skip: night-only task during daytime
}

# ── Model selection (3 layers: env > frontmatter > default) ──────
get_model() {
  local task_dir="$1" source="$2"
  # 1. Override global
  [ -n "${CLAU_MODEL:-}" ] && echo "$CLAU_MODEL" && return
  # 2. Frontmatter
  local fm
  fm=$(parse_frontmatter "$task_dir/CLAUDE.md" "model")
  [ -n "$fm" ] && echo "$fm" && return
  # 3. Default by type
  [ "$source" = "recurring" ] && echo "$DEFAULT_MODEL_RECURRING" || echo "$DEFAULT_MODEL_PENDING"
}

# ── Timeout selection ────────────────────────────────────────────
get_timeout() {
  local task_dir="$1" source="$2"
  local fm
  fm=$(parse_frontmatter "$task_dir/CLAUDE.md" "timeout")
  [ -n "$fm" ] && echo "$fm" && return
  [ "$source" = "recurring" ] && echo "$DEFAULT_TIMEOUT_RECURRING" || echo "$DEFAULT_TIMEOUT_PENDING"
}

# ── MCP selection ────────────────────────────────────────────────
get_mcp_flags() {
  local task_dir="$1"
  local mcp
  mcp=$(parse_frontmatter "$task_dir/CLAUDE.md" "mcp")
  if [ "$mcp" = "true" ]; then
    echo ""  # no flag = use default MCP from ~/.claude/
  else
    echo "--mcp-config $EPHEMERAL/no-mcp.json"
  fi
}

# ── Max turns ────────────────────────────────────────────────────
get_max_turns() {
  local task_dir="$1"
  local fm
  fm=$(parse_frontmatter "$task_dir/CLAUDE.md" "max_turns")
  [ -n "$fm" ] && echo "$fm" && return
  echo "$DEFAULT_MAX_TURNS"
}

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
  # Check schedule before claiming
  if ! should_run_task "$TASKS/$source_dir/$task" "$source_dir"; then
    echo "[clau] '$task' schedule=night, agora é dia — skip"
    return 1
  fi
  if ! mv "$TASKS/$source_dir/$task" "$TASKS/running/$task" 2>/dev/null; then
    echo "[clau] '$task' sumiu (race condition?) — skip"
    return 1
  fi
  local task_timeout
  task_timeout=$(get_timeout "$TASKS/running/$task" "$source_dir")
  cat > "$TASKS/running/$task/.lock" <<EOF
started=$(date -u +%Y-%m-%dT%H:%M:%SZ)
timeout=$task_timeout
source=$source_dir
pid=$$
EOF
  echo "[clau] Claimed '$task' ($source_dir, timeout=${task_timeout}s)"
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

# ── Executar UMA task ────────────────────────────────────────────
run_single_task() {
  local task="$1" source_dir="$2" is_recurring="$3"
  local block logfile
  block=$(build_task_block "$task" "$source_dir" "$is_recurring")
  local memoria=""
  [ -f "$TASKS/running/$task/memoria.md" ] && memoria="
### Memória evolutiva
$(cat "$TASKS/running/$task/memoria.md")"

  logfile="$EPHEMERAL/notes/$task/last-run.log"
  mkdir -p "$EPHEMERAL/notes/$task"

  local task_timeout task_model task_max_turns mcp_flags_str
  task_timeout=$(get_timeout "$TASKS/running/$task" "$source_dir")
  task_model=$(get_model "$TASKS/running/$task" "$source_dir")
  task_max_turns=$(get_max_turns "$TASKS/running/$task")
  mcp_flags_str=$(get_mcp_flags "$TASKS/running/$task")

  echo "[clau:$task] Iniciando Claude (model=$task_model, timeout=${task_timeout}s, turns=$task_max_turns, $(date -u +%H:%M:%S))..."

  # Build mcp flags array
  local mcp_flags=()
  if [ -n "$mcp_flags_str" ]; then
    # shellcheck disable=SC2086
    mcp_flags=($mcp_flags_str)
  fi

  timeout "$task_timeout" claude --permission-mode bypassPermissions --model "$task_model" \
    --max-turns "$task_max_turns" \
    "${mcp_flags[@]}" \
    -p "Modo autônomo. Tarefa: $task
Hora atual: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Budget: ${task_timeout}s (~$(( task_timeout / 60 ))min)
Model: $task_model

$block
$memoria

## Instruções de execução
1. Siga o protocolo descrito no CLAUDE.md da task
2. Gere o artefato concreto que a task pede
3. Atualize memoria.md em tasks/running/$task/memoria.md com timestamp, o que fez, o que aprendeu, próximos passos
4. Atualize contexto efêmero em $EPHEMERAL/notes/$task/contexto.md
5. Se a task permite auto-evolução, reflita e edite o CLAUDE.md se necessário
6. Se identificar melhorias/ideias/problemas, salve sugestão em $WORKSPACE/vault/sugestoes/\$(date +%Y-%m-%d)-<topico>.md

## Ao finalizar
$([ "$is_recurring" = "1" ] && echo "- Mova $TASKS/running/$task para $TASKS/recurring/$task" || echo "- Se sucesso: mova $TASKS/running/$task para $TASKS/done/$task")
$([ "$is_recurring" != "1" ] && echo "- Se falha: mova $TASKS/running/$task para $TASKS/failed/$task")
- Registre resultado em $EPHEMERAL/notes/$task/historico.log (formato: TIMESTAMP | ok ou fail | duração)
- Registre uso em $EPHEMERAL/usage/$(date +%Y-%m).jsonl: {\"date\":\"TIMESTAMP\",\"task\":\"$task\",\"duration\":N,\"status\":\"STATUS\",\"type\":\"$([ "$is_recurring" = "1" ] && echo recurring || echo oneshot)\",\"model\":\"$task_model\"}
- Resuma em uma linha." 2>&1 | if [ "$CLAU_VERBOSE" = "1" ]; then tee "$logfile"; else cat > "$logfile"; fi
  local exit_code=${PIPESTATUS[0]}

  if [ $exit_code -eq 0 ]; then
    echo "[clau:$task] OK ($(date -u +%H:%M:%S))"
  else
    echo "[clau:$task] FAIL exit=$exit_code ($(date -u +%H:%M:%S))"
  fi
  echo "[clau:$task] --- últimas linhas ---"
  tail -5 "$logfile" 2>/dev/null | while IFS= read -r line; do echo "[clau:$task]   $line"; done
  echo "[clau:$task] --- log: $logfile ---"
  return $exit_code
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
  run_single_task "$SPECIFIC_TASK" "$source_dir" "$is_recurring" || true

  echo "[clau] Done (task específica)."
  exit 0
fi

# ── Coletar tasks: RECURRING primeiro (filtradas por schedule), depois PENDING ──
task_count=0
TASK_NAMES=()
TASK_SOURCES=()
TASK_RECURRING=()

# 1) Recurring — ordered by last execution (oldest first), filtered by schedule
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
  TASK_NAMES+=("$task")
  TASK_SOURCES+=("recurring")
  TASK_RECURRING+=("1")
  task_count=$((task_count + 1))
done

# 2) Pending (one-shot) — alphabetical
for task in $(ls -1 "$TASKS/pending/" 2>/dev/null | grep -v '\.gitkeep' | sort); do
  [ -z "$task" ] && continue
  [ "$task_count" -ge "$MAX_TASKS" ] && break
  claim_task "$task" "pending" || continue
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
echo "[clau] Lançando em batches de $MAX_PARALLEL..."

# ── Lançar tasks em batches paralelos ────────────────────────────
start_time=$SECONDS
ok_count=0
fail_count=0
batch_num=0

for ((batch_start=0; batch_start<task_count; batch_start+=MAX_PARALLEL)); do
  batch_num=$((batch_num + 1))
  batch_end=$((batch_start + MAX_PARALLEL))
  [ "$batch_end" -gt "$task_count" ] && batch_end=$task_count

  echo "[clau] -- Batch $batch_num: tasks $((batch_start+1))-$batch_end de $task_count --"

  PIDS=()
  BATCH_TASKS=()

  for ((i=batch_start; i<batch_end; i++)); do
    t="${TASK_NAMES[$i]}"
    s="${TASK_SOURCES[$i]}"
    r="${TASK_RECURRING[$i]}"
    echo "[clau] Lançando '$t' (${s}, model=$(get_model "$TASKS/running/$t" "$s"))..."
    (run_single_task "$t" "$s" "$r" || true) &
    PIDS+=($!)
    BATCH_TASKS+=("$t")
  done

  echo "[clau] ${#PIDS[@]} processos no batch $batch_num. Aguardando..."

  for j in "${!PIDS[@]}"; do
    pid=${PIDS[$j]}
    task=${BATCH_TASKS[$j]}
    if wait "$pid" 2>/dev/null; then
      echo "[clau] OK '$task' (PID $pid)"
      ok_count=$((ok_count + 1))
    else
      echo "[clau] FAIL '$task' (PID $pid, exit $?)"
      fail_count=$((fail_count + 1))
    fi
  done

  echo "[clau] Batch $batch_num concluído."
done

duration=$((SECONDS - start_time))
echo "[clau] Done — $task_count tasks, ${ok_count} ok, ${fail_count} falhas, ${duration}s total"

# ── Dashboard generation ─────────────────────────────────────────
generate_dashboard() {
  local vault_dir="$WORKSPACE/vault"
  local dashboard="$vault_dir/dashboard.md"
  mkdir -p "$vault_dir"

  local now
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local recurring_count pending_count running_count
  recurring_count=$(ls -1 "$TASKS/recurring/" 2>/dev/null | grep -cv '\.gitkeep' || echo "0")
  pending_count=$(ls -1 "$TASKS/pending/" 2>/dev/null | grep -cv '\.gitkeep' || echo "0")
  running_count=$(ls -1 "$TASKS/running/" 2>/dev/null | grep -cv '\.gitkeep' || echo "0")

  cat > "$dashboard" <<DASH
# Claudinho Dashboard
Atualizado: $now

## Saúde do Sistema
- Última execução: $now (${duration}s, $ok_count ok / $fail_count falhas)
- Tasks: $recurring_count recurring, $pending_count pending, $running_count running

## Últimas Execuções
| Task | Status | Model | Quando |
|------|--------|-------|--------|
DASH

  # Parse recent entries from usage JSONL
  local usage_file="$EPHEMERAL/usage/$(date +%Y-%m).jsonl"
  if [ -f "$usage_file" ]; then
    tail -15 "$usage_file" | while IFS= read -r line; do
      local t_name t_status t_date t_model
      t_name=$(echo "$line" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('task','?'))" 2>/dev/null || echo "?")
      t_status=$(echo "$line" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','?'))" 2>/dev/null || echo "?")
      t_date=$(echo "$line" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('date','?'))" 2>/dev/null || echo "?")
      t_model=$(echo "$line" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('model','?'))" 2>/dev/null || echo "?")
      echo "| $t_name | $t_status | $t_model | $t_date |" >> "$dashboard"
    done
  fi

  cat >> "$dashboard" <<DASH

## Tasks Recorrentes
| Task | Schedule | Model |
|------|----------|-------|
DASH

  for dir in "$TASKS/recurring"/*/; do
    [ -d "$dir" ] || continue
    local tname tschedule tmodel
    tname=$(basename "$dir")
    tschedule=$(parse_frontmatter "$dir/CLAUDE.md" "schedule")
    tschedule=${tschedule:-night}
    tmodel=$(parse_frontmatter "$dir/CLAUDE.md" "model")
    tmodel=${tmodel:-$DEFAULT_MODEL_RECURRING}
    echo "| $tname | $tschedule | $tmodel |" >> "$dashboard"
  done

  cat >> "$dashboard" <<DASH

## Fila Pendente
DASH

  for dir in "$TASKS/pending"/*/; do
    [ -d "$dir" ] || continue
    local tname tfirst
    tname=$(basename "$dir")
    tfirst=$(head -3 "$dir/CLAUDE.md" 2>/dev/null | grep -v '^---' | grep -v '^$' | head -1 || echo "")
    echo "- [ ] **$tname** — $tfirst" >> "$dashboard"
  done

  # Alerts
  if [ "$fail_count" -gt 0 ] || [ "$running_count" -gt 0 ]; then
    cat >> "$dashboard" <<DASH

## Alertas
DASH
    [ "$fail_count" -gt 0 ] && echo "- $fail_count tasks falharam nesta execução" >> "$dashboard"
    [ "$running_count" -gt 0 ] && echo "- $running_count tasks órfãs em running/" >> "$dashboard"
  fi

  echo "[clau] Dashboard gerado: $dashboard"
}

generate_dashboard 2>/dev/null || echo "[clau] Dashboard generation failed (non-critical)"

# ── Health endpoint (JSON for Waybar) ────────────────────────────
generate_health() {
  local health_file="$EPHEMERAL/health.json"
  local status_text="ok"
  local status_class="ok"
  [ "$fail_count" -gt 0 ] && status_text="${ok_count}ok/${fail_count}fail" && status_class="warning"
  [ "$ok_count" -eq 0 ] && [ "$fail_count" -gt 0 ] && status_class="critical"

  cat > "$health_file" <<JSON
{"text":"${ok_count}/${task_count}","tooltip":"Claudinho: ${ok_count} ok, ${fail_count} fail, ${duration}s","class":"$status_class","alt":"$status_text"}
JSON
  echo "[clau] Health endpoint: $health_file"
}

generate_health 2>/dev/null || true

# ── Desktop notification ─────────────────────────────────────────
if command -v notify-send &>/dev/null; then
  _icon="dialog-information"
  [ "$fail_count" -gt 0 ] && _icon="dialog-warning"
  notify-send -i "$_icon" "Claudinho" "$ok_count ok, $fail_count falhas em ${duration}s" 2>/dev/null || true
fi
