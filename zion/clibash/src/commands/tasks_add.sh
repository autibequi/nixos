# Create a new task card in TODO/
local title="${args[title]}"
local model="${args[--model]:-haiku}"
local steps="${args[--steps]:-30}"
local when="${args[--when]:-$(date +%Y%m%d_%H_%M)}"
local agent="${args[--agent]:-}"
zion_load_config

local tasks="${OBSIDIAN_PATH:-$HOME/.ovault/Work}/tasks"

# Fallback paths
if [ ! -d "$tasks" ]; then
  for try in /workspace/obsidian/tasks "$HOME/obsidian/tasks"; do
    [ -d "$try" ] && tasks="$try" && break
  done
fi

mkdir -p "$tasks/TODO" "$tasks/DOING" "$tasks/DONE"

# Sanitize title for filename
local safe_title
safe_title=$(echo "$title" | tr ' ' '-' | tr -cd 'a-zA-Z0-9_-')

local filename="${when}_${safe_title}.md"
local filepath="$tasks/TODO/$filename"

# Timeout by model
local timeout
case "$model" in
  haiku)  timeout=900  ;;
  opus)   timeout=3600 ;;
  *)      timeout=1800 ;;
esac

if [ -n "$agent" ]; then
  printf '%s\n' \
    "---" \
    "model: $model" \
    "timeout: $timeout" \
    "mcp: false" \
    "agent: $agent" \
    "---" \
    "# $title" \
    "" \
    "Run the $agent agent." \
    "" \
    "#steps${steps}" \
    > "$filepath"
else
  printf '%s\n' \
    "---" \
    "model: $model" \
    "timeout: $timeout" \
    "mcp: false" \
    "---" \
    "# $title" \
    "" \
    "## Instructions" \
    "(fill in)" \
    "" \
    "#steps${steps}" \
    > "$filepath"
fi

echo "Created: $filepath"
