#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/workspace"
TASKS="$WORKSPACE/tasks"
TIMEOUT="${1:-1200}"

# 1) Reap stuck tasks
for lock in "$TASKS/running"/*/.lock; do
  [ -f "$lock" ] || continue
  started=$(grep '^started=' "$lock" | cut -d= -f2)
  elapsed=$(( $(date +%s) - $(date -d "$started" +%s) ))
  if [ "$elapsed" -gt $(( TIMEOUT + 300 )) ]; then
    task=$(dirname "$lock")
    name=$(basename "$task")
    mv "$task" "$TASKS/failed/$name"
    echo "timeout after ${elapsed}s" > "$TASKS/failed/$name/.result"
    rm -f "$TASKS/failed/$name/.lock"
  fi
done

# 2) Pick oldest pending task
TASK=$(ls -1 "$TASKS/pending/" 2>/dev/null | grep -v '\.gitkeep' | sort | head -1)
[ -z "${TASK:-}" ] && echo "Sem tarefas pendentes." && exit 0

# 3) Move to running + lock
mv "$TASKS/pending/$TASK" "$TASKS/running/$TASK"
cat > "$TASKS/running/$TASK/.lock" <<EOF
pid=$$
started=$(date -u +%Y-%m-%dT%H:%M:%SZ)
timeout=$TIMEOUT
EOF

# 4) Execute
INSTRUCTIONS=$(cat "$TASKS/running/$TASK/CLAUDE.md")
START=$SECONDS

if timeout "$TIMEOUT" claude --permission-mode bypassPermissions \
  -p "Modo autônomo. Tarefa: $TASK
Diretório: $TASKS/running/$TASK

$INSTRUCTIONS

Ao terminar, resuma em uma linha." 2>&1; then
  mv "$TASKS/running/$TASK" "$TASKS/done/$TASK"
  echo "ok: $((SECONDS-START))s" > "$TASKS/done/$TASK/.result"
else
  mv "$TASKS/running/$TASK" "$TASKS/failed/$TASK"
  echo "fail: exit $?, $((SECONDS-START))s" > "$TASKS/failed/$TASK/.result"
fi

rm -f "$TASKS/done/$TASK/.lock" "$TASKS/failed/$TASK/.lock"

# 5) Log usage
mkdir -p "$WORKSPACE/.ephemeral/usage"
echo "{\"date\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"task\":\"$TASK\",\"duration\":$((SECONDS-START))}" \
  >> "$WORKSPACE/.ephemeral/usage/$(date +%Y-%m).jsonl"
