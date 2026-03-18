running_dir="$zion_vault_dir/_agent/tasks/running"
for dir in "$running_dir"/*/; do
  [[ -d "$dir" ]] || continue
  name=$(basename "$dir")
  source=$(grep '^source=' "$dir/.lock" 2>/dev/null | cut -d= -f2 || echo "pending")
  rm -f "$dir/.lock"
  if [[ "$source" == "recurring" ]]; then
    rm -rf "$dir"
    echo "[reset] $name recurring removed"
  else
    mkdir -p "$zion_vault_dir/_agent/tasks/pending"
    mv "$dir" "$zion_vault_dir/_agent/tasks/pending/$name"
    echo "[reset] $name → pending/"
  fi
done
mkdir -p "$zion_ephemeral/locks"
rm -f "$zion_ephemeral/.kanban.lock" "$zion_ephemeral/locks"/*.lock 2>/dev/null || true
echo "[reset] done"
