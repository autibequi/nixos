# leech git append — cria commit de append no branch atual
# Alias legado de git sandbox
leech_load_config
local cwd="${args[dir]:-$(pwd)}"
cd "$cwd" || { echo "leech: dir not found: $cwd" >&2; exit 1; }
exec git add -A && git commit -m "chore: append $(date +%Y%m%d_%H%M)"
