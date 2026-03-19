# Create a new task card in TODO/
local name="${args[name]}"
local model="${args[--model]:-haiku}"
local timeout="${args[--timeout]:-300}"
local when="${args[--when]:-$(date +%Y%m%d_%H_%M)}"
local agent="${args[--agent]:-}"
zion_load_config
local vault="${OBSIDIAN_PATH:-$HOME/.ovault/Zion}/tasks"

local filename="${when}_${name}.md"
local filepath="$vault/TODO/$filename"

mkdir -p "$vault/TODO"

if [ -n "$agent" ]; then
  printf '%s\n' \
    "---" \
    "model: $model" \
    "timeout: $timeout" \
    "mcp: false" \
    "agent: $agent" \
    "---" \
    "# $name" \
    "" \
    "Run the $agent agent. See agent memory at agents/memory/${agent}.md." \
    > "$filepath"
else
  printf '%s\n' \
    "---" \
    "model: $model" \
    "timeout: $timeout" \
    "mcp: false" \
    "---" \
    "# $name" \
    "" \
    "## Instructions" \
    "(fill in)" \
    > "$filepath"
fi

echo "Created: $filepath"
