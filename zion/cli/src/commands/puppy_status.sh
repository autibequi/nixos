# Mostra estado do container puppy e tasks em doing/.
zion_load_config

PUPPY_PROJECT="${PUPPY_PROJECT:-puppy-workers}"
PUPPY_COMPOSE="$zion_cli_dir/docker-compose.puppy.yml"

echo "=== Container ==="
OBSIDIAN_PATH="$zion_obsidian_path" \
  docker compose -f "$PUPPY_COMPOSE" -p "$PUPPY_PROJECT" ps 2>/dev/null || \
  echo "Nenhum container puppy rodando."

echo ""
echo "=== Tasks em doing/ ==="
vault="${zion_obsidian_path}/tasks/doing"
if [ -d "$vault" ] && [ -n "$(ls -A "$vault" 2>/dev/null)" ]; then
  for d in "$vault"/*/; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    lock_info=""
    [ -f "$d/.lock" ] && lock_info=" (locked: $(grep '^worker=' "$d/.lock" 2>/dev/null | cut -d= -f2))"
    echo "  $name$lock_info"
  done
else
  echo "  (nenhuma)"
fi

echo ""
echo "=== State (últimas execuções) ==="
OBSIDIAN_PATH="$zion_obsidian_path" \
  docker compose -f "$PUPPY_COMPOSE" -p "$PUPPY_PROJECT" exec -T puppy \
  python3 -c '
import json, sys
try:
    s = json.load(open("/workspace/.ephemeral/scheduler/state.json"))
    print(f"Last tick: {s.get(\"last_tick\", \"never\")}")
    for name, t in sorted(s.get("tasks", {}).items()):
        status = t.get("last_status", "?")
        avg = t.get("avg_duration_s", 0)
        total = t.get("runs_total", 0)
        failed = t.get("runs_failed", 0)
        print(f"  {name:<20} status={status:<7} avg={avg}s  runs={total}  failed={failed}")
except FileNotFoundError:
    print("  (sem state.json — daemon ainda nao rodou)")
except Exception as e:
    print(f"  (erro: {e})")
' 2>/dev/null || echo "  (container nao esta rodando)"
