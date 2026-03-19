# zion hooks <hook> [KEY=VALUE...] — Executa um hook e mostra o output (preview do que seria injetado).
# Util para debug de session-start, pre-tool-use, etc. sem abrir uma sessao completa.

HOOKS_DIR=""
for _d in \
  "/zion/hooks/claude-code" \
  "${ZION_ROOT:-${HOME}/nixos/zion}/hooks/claude-code" \
  "/workspace/mnt/zion/hooks/claude-code"; do
  [[ -d "$_d" ]] && HOOKS_DIR="$_d" && break
done

# --list: lista hooks disponíveis
if [[ -n "${args[--list]:-}" ]]; then
  if [[ -z "$HOOKS_DIR" ]]; then
    echo "hooks: diretório não encontrado" >&2; exit 1
  fi
  echo "Hooks disponíveis em $HOOKS_DIR:"
  for f in "$HOOKS_DIR"/*.sh "$HOOKS_DIR"/*.json; do
    [[ -f "$f" ]] && printf "  %s\n" "$(basename "$f" | sed 's/\.\(sh\|json\)$//')"
  done
  exit 0
fi

HOOK="${args[hook]}"

if [[ -z "$HOOKS_DIR" ]]; then
  echo "hooks: diretório de hooks não encontrado" >&2; exit 1
fi

# Resolve o arquivo: tenta .sh e .json
HOOK_FILE=""
for ext in sh json ""; do
  candidate="$HOOKS_DIR/${HOOK}${ext:+.$ext}"
  [[ -f "$candidate" ]] && HOOK_FILE="$candidate" && break
done

if [[ -z "$HOOK_FILE" ]]; then
  echo "hooks: hook '$HOOK' não encontrado em $HOOKS_DIR" >&2
  echo "Use 'zion hooks --list' para ver disponíveis." >&2
  exit 1
fi

# Aplica overrides de env passados como KEY=VALUE ou key=value
if [[ -n "${args[env_overrides]:-}" ]]; then
  IFS=' ' read -ra _overrides <<< "${args[env_overrides]}"
  for _kv in "${_overrides[@]}"; do
    if [[ "$_kv" == *=* ]]; then
      _key="${_kv%%=*}"
      _val="${_kv#*=}"
      # normaliza para maiúsculas (PERSONALITY=OFF e personality=OFF sao equivalentes)
      export "${_key^^}=${_val}"
    fi
  done
fi

exec bash "$HOOK_FILE"
