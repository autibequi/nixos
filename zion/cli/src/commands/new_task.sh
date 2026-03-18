name="${args[name]:-}"
[[ -n "$name" ]] || { echo "Uso: zion new-task <name> [--type pending|recurring] [--model haiku|sonnet] [--clock every10|every60] [--timeout N]" >&2; exit 1; }
type="${flag_type:-pending}"
model="${flag_model:-}"
clock="${flag_clock:-}"
timeout="${flag_timeout:-}"
[[ -n "$model" ]] || { [[ "$type" == "recurring" ]] && model="haiku" || model="sonnet"; }
[[ -n "$clock" ]] || { [[ "$type" == "recurring" ]] && clock="every10" || clock="every60"; }
[[ -n "$timeout" ]] || { [[ "$clock" == "every10" ]] && timeout="120" || timeout="300"; }
task_dir="$zion_vault_dir/_agent/tasks/$type/$name"
mkdir -p "$task_dir"
{
  echo "---"
  echo "clock: $clock"
  echo "timeout: $timeout"
  echo "model: $model"
  echo "schedule: always"
  echo "---"
  echo "# $name"
  echo ""
  echo "## Objetivo"
  echo ""
  echo "## O que fazer"
  echo ""
  echo "## Entregavel"
  echo "Atualize \`<diretorio de contexto>/contexto.md\`."
} > "$task_dir/CLAUDE.md"
kanban_col="Backlog"
kanban_file="$zion_vault_dir/kanban.md"
if [[ "$type" == "recurring" ]]; then
  kanban_col="Recorrentes"
  kanban_file="$zion_vault_dir/_agent/scheduled.md"
fi
card="- [ ] **$name** #$type $(date +%Y-%m-%d) \`$model\`"
export KANBAN_FILE="$kanban_file"
# shellcheck source=/dev/null
source "$zion_nixos_scripts/kanban-sync.sh" 2>/dev/null && kanban_add_card "$kanban_col" "$card" 2>/dev/null || echo "[AVISO] Não conseguiu adicionar card no kanban"
echo "Task: $task_dir/ ($model, ${timeout}s)"
