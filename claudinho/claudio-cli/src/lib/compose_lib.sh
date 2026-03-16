# Shared helpers for claudio CLI (compose file, mount path, project names).
# Sourced by generated script. Uses CLAUDIO_NIXOS_DIR, OBSIDIAN_PATH, args, flag_*.

claudio_nixos_dir="${CLAUDIO_NIXOS_DIR:-$HOME/nixos}"
claudio_compose_file="$claudio_nixos_dir/claudinho/docker-compose.claude.yml"
claudio_obsidian_path="${OBSIDIAN_PATH:-$HOME/.ovault}"

# Resolve mount directory: first positional arg or default ~/projects
claudio_resolve_dir() {
  local dir="${args[0]:-$HOME/projects}"
  if [[ -n "$dir" ]]; then
    (cd "$dir" 2>/dev/null && pwd) || { echo "claudio: dir not found: $dir" >&2; exit 1; }
  else
    echo "$HOME/projects"
  fi
}

# Slug from dir basename (lowercase, alphanumeric + hyphen)
claudio_proj_slug() {
  local d="$1"
  basename "$d" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/-*$//'
}

# Project name for claude (clau-SLUG or clau-SLUG-INSTANCE)
claudio_proj_name() {
  local slug="$1"
  local instance="${flag_instance:-}"
  local name="clau-${slug}"
  [[ -n "$instance" && "$instance" != "1" ]] && name="${name}-${instance}"
  echo "$name"
}

# Project name for opencode (persistent sandbox)
claudio_proj_name_open() {
  local slug="$1"
  echo "clau-${slug}-open"
}

# Mount opts: --rw (default for run) or --ro
claudio_mount_opts() {
  if [[ -n "${flag_rw:-}" ]]; then echo "rw"; elif [[ -n "${flag_ro:-}" ]]; then echo "ro"; else echo "rw"; fi
}

# Model flag for claude binary
claudio_model_flag() {
  if [[ -n "${flag_haiku:-}" ]]; then echo "--model claude-haiku-4-5-20251001"; elif [[ -n "${flag_opus:-}" ]]; then echo "--model claude-opus-4-6"; else echo ""; fi
}
