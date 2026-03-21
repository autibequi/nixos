# Lista o inbox ou adiciona uma entrada
local obsidian="${OBSIDIAN_PATH:-$HOME/.ovault/Work}"
local inbox_file="$obsidian/inbox/inbox.md"

# Fallback path
if [ ! -f "$inbox_file" ]; then
  for try in "/workspace/obsidian/inbox/inbox.md" "$HOME/obsidian/inbox/inbox.md"; do
    [ -f "$try" ] && inbox_file="$try" && break
  done
fi

message="${args[message]*}"

if [ -z "$message" ]; then
  # Sem args: mostrar inbox
  if [ -f "$inbox_file" ]; then
    cat "$inbox_file"
  else
    echo "Inbox nao encontrado: $inbox_file"
    exit 1
  fi
else
  # Com texto: adicionar entrada
  if [ ! -f "$inbox_file" ]; then
    echo "Inbox nao encontrado: $inbox_file"
    exit 1
  fi
  DATE=$(date +%Y-%m-%d)
  cat >> "$inbox_file" << ENTRY

### [user] ${DATE} — nota

${message}
ENTRY
  echo "Adicionado ao inbox."
fi
