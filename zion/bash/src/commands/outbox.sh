# Lista o outbox
local obsidian="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"
local outbox_dir="$obsidian/outbox"

# Fallback path
if [ ! -d "$outbox_dir" ]; then
  for try in "/workspace/obsidian/outbox" "$HOME/obsidian/outbox"; do
    [ -d "$try" ] && outbox_dir="$try" && break
  done
fi

if [ ! -d "$outbox_dir" ]; then
  echo "Outbox nao encontrado: $outbox_dir"
  exit 1
fi

files=$(ls -1 "$outbox_dir" 2>/dev/null)
if [ -z "$files" ]; then
  echo "Outbox vazio."
else
  echo "Outbox ($outbox_dir):"
  echo "$files" | sed 's/^/  /'
fi
