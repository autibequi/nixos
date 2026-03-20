# List task cards or execution log
zion_load_config
local compose_file="${ZION_ROOT:-$HOME/nixos/zion}/cli/docker-compose.puppy.yml"
local show_all="${args[--all]:-}"
local show_log="${args[--log]:-}"
local log_lines="${args[--lines]:-20}"
local obsidian="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"

# --log: mostra log de execucao
if [ -n "$show_log" ]; then
  if docker compose -f "$compose_file" ps --status running 2>/dev/null | grep -q puppy; then
    docker compose -f "$compose_file" exec -T -u claude puppy bash -c "
      LOG=/workspace/obsidian/tasks/log.md
      if [ ! -f \$LOG ]; then echo 'No task log found'; exit 0; fi
      echo '=== Task Log (last $log_lines) ==='
      tail -n $log_lines \$LOG
    " 2>/dev/null
  else
    local logfile="$obsidian/tasks/log.md"
    [ ! -f "$logfile" ] && logfile="/workspace/obsidian/tasks/log.md"
    if [ ! -f "$logfile" ]; then
      echo "No task log found (puppy not running)"
      exit 1
    fi
    echo "=== Task Log (last $log_lines) ==="
    tail -n "$log_lines" "$logfile"
  fi
  exit 0
fi

# cards mode
local cmd="T=/workspace/obsidian/tasks; echo '=== TODO ==='; ls \$T/TODO/*.md 2>/dev/null | xargs -I{} basename {} | sort || echo '  (empty)'; echo; echo '=== DOING ==='; ls \$T/DOING/*.md 2>/dev/null | xargs -I{} basename {} | sort || echo '  (empty)'"
if [ -n "$show_all" ]; then
  cmd="$cmd; echo; echo '=== DONE (last 20) ==='; ls -t \$T/DONE/*.md 2>/dev/null | head -20 | xargs -I{} basename {} || echo '  (empty)'"
fi

# Tenta via container puppy
if docker compose -f "$compose_file" ps --status running 2>/dev/null | grep -q puppy; then
  docker compose -f "$compose_file" exec -T -u claude puppy bash -c "$cmd" 2>/dev/null
  exit 0
fi

# Fallback local: le direto do filesystem
local tasks="$obsidian/tasks"
[ ! -d "$tasks" ] && tasks="/workspace/obsidian/tasks"

if [ ! -d "$tasks" ]; then
  echo "Tasks dir not found (puppy not running e path local nao encontrado)"
  exit 1
fi

echo "=== TODO ==="
ls "$tasks/TODO/"*.md 2>/dev/null | xargs -I{} basename {} | sort || echo "  (empty)"
echo ""
echo "=== DOING ==="
ls "$tasks/DOING/"*.md 2>/dev/null | xargs -I{} basename {} | sort || echo "  (empty)"
if [ -n "$show_all" ]; then
  echo ""
  echo "=== DONE (last 20) ==="
  ls -t "$tasks/DONE/"*.md 2>/dev/null | head -20 | xargs -I{} basename {} || echo "  (empty)"
fi
