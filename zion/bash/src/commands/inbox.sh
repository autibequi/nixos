# Lista o inbox
local obsidian="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"
local inbox_dir="$obsidian/inbox"

# Fallback path
if [ ! -d "$inbox_dir" ]; then
  for try in "/workspace/obsidian/inbox" "$HOME/obsidian/inbox"; do
    [ -d "$try" ] && inbox_dir="$try" && break
  done
fi

if [ ! -d "$inbox_dir" ]; then
  echo "Inbox nao encontrado: $inbox_dir"
  exit 1
fi

files=$(ls -1 "$inbox_dir" 2>/dev/null)
if [ -z "$files" ]; then
  echo "Inbox vazio."
else
  echo "Inbox ($inbox_dir):"
  echo "$files" | sed 's/^/  /'
fi
