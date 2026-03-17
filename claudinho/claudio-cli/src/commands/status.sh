echo "=== Scheduler (container 24/7, tick every 10 min) ==="
docker ps --filter "label=com.docker.compose.service=scheduler" --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}" 2>/dev/null || podman ps --filter "label=com.docker.compose.service=scheduler" --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}" 2>/dev/null || echo "(nenhum)"
echo ""
echo "=== Workers (on-demand) ==="
docker ps --filter "name=_worker_" --format "table {{.ID}}\t{{.Status}}\t{{.RunningFor}}" 2>/dev/null || podman ps --filter "name=_worker_" --format "table {{.ID}}\t{{.Status}}\t{{.RunningFor}}" 2>/dev/null || echo "(nenhum)"
scheduled="$claudio_vault_dir/_agent/scheduled.md"
kanban="$claudio_vault_dir/kanban.md"
echo ""
echo "=== Kanban ==="
if [[ -f "$scheduled" ]]; then
  for col in "Recorrentes" "Em Execução"; do
    count=0 in_col=0
    while IFS= read -r line; do
      if [[ "$line" == "## $col" ]]; then in_col=1; continue; fi
      if [[ "$line" =~ ^## ]] && [[ "$in_col" == "1" ]]; then break; fi
      if [[ "$in_col" == "1" ]] && echo "$line" | grep -q '^- \['; then count=$((count+1)); fi
    done < "$scheduled"
    echo "  $col: $count"
  done
fi
if [[ -f "$kanban" ]]; then
  for col in "Backlog" "Em Andamento" "Aprovado" "Falhou"; do
    count=0 in_col=0
    while IFS= read -r line; do
      if [[ "$line" == "## $col" ]]; then in_col=1; continue; fi
      if [[ "$line" =~ ^## ]] && [[ "$in_col" == "1" ]]; then break; fi
      if [[ "$in_col" == "1" ]] && echo "$line" | grep -q '^- \['; then count=$((count+1)); fi
    done < "$kanban"
    echo "  $col: $count"
  done
fi
echo ""
echo "=== Em Andamento ==="
in_col=0
while IFS= read -r line; do
  if [[ "$line" == "## Em Andamento" ]]; then in_col=1; continue; fi
  if [[ "$line" =~ ^## ]] && [[ "$in_col" == "1" ]]; then break; fi
  if [[ "$in_col" == "1" ]] && echo "$line" | grep -q '^- \['; then echo "  $line"; fi
done < "$kanban" 2>/dev/null || echo "  (vazio)"
