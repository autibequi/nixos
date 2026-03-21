# zion claude usage — Estatísticas de uso Claude (OAuth / claude.ai).
# Delega para o script do waybar; saída no formato que o usage bar consome (--waybar) ou JSON bruto.
# Uso: zion claude usage [--waybar] [--json] [--refresh]

# Resolve o script: repo (stow) ou deploy em ~/.config/waybar
zion_nixos_dir="${ZION_NIXOS_DIR:-$HOME/nixos}"
usage_script=""
for candidate in \
  "$HOME/.config/waybar/claude-oauth-usage.sh" \
  "$zion_nixos_dir/stow/.config/waybar/claude-oauth-usage.sh" \
  "$HOME/nixos/stow/.config/waybar/claude-oauth-usage.sh" \
  "/workspace/mnt/stow/.config/waybar/claude-oauth-usage.sh"; do
  if [[ -x "$candidate" ]] || [[ -f "$candidate" ]]; then
    usage_script="$candidate"
    break
  fi
done

if [[ -z "$usage_script" ]] || [[ ! -f "$usage_script" ]]; then
  echo "zion claude usage: script não encontrado (procure em ~/.config/waybar/claude-oauth-usage.sh ou repo stow)" >&2
  exit 1
fi

# --no-cache / --refresh → passa --refresh para o script
_no_cache=""
[[ -n "${args[--no-cache]:-}" || -n "${args[--refresh]:-}" ]] && _no_cache="1"

if [[ -n "${args[--waybar]:-}" ]]; then
  run_args=(--waybar)
  [[ -n "$_no_cache" ]] && run_args+=(--refresh)
  exec bash "$usage_script" "${run_args[@]}"
else
  run_args=()
  [[ -n "$_no_cache" ]] && run_args+=(--refresh)
  exec bash "$usage_script" "${run_args[@]}"
fi
