# Regenera CLI, instala symlink e atualiza bootstrap
cli_dir="$zion_compose_dir"
nixos_dir="$zion_nixos_dir"
bin_dest="$nixos_dir/stow/.local/bin/zion"
log_file="$(mktemp /tmp/zion-update-XXXXXX.log)"
trap 'rm -f "$log_file"' EXIT

# Cores
_grn="\033[32m" _red="\033[31m" _dim="\033[2m" _rst="\033[0m" _bld="\033[1m"

_step() {
  local n=$1 total=$2 label=$3
  printf "  \033[2m[%d/%d]\033[0m %s" "$n" "$total" "$label"
}

_ok()   { printf " \033[32m✓\033[0m\n"; }
_fail() { printf " \033[31m✗\033[0m\n"; cat "$log_file" >&2; exit 1; }

_spin() {
  local pid=$1 frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r  \033[2m[%s/%s]\033[0m %s \033[33m%s\033[0m" \
      "$2" "$3" "$4" "${frames:$((i % ${#frames})):1}"
    sleep 0.08
    i=$((i + 1))
  done
}

printf "${_bld}Atualizando zion...${_rst}\n"

# ── 1/3 bashly generate ─────────────────────────────────────────────
_step 1 3 "Gerando CLI"
( cd "$cli_dir" && LANG=en_US.UTF-8 RUBYOPT="-E utf-8" bashly generate >"$log_file" 2>&1 ) &
pid=$!; _spin $pid 1 3 "Gerando CLI"
wait $pid && _ok || _fail

# ── 2/3 symlink ─────────────────────────────────────────────────────
_step 2 3 "Instalando symlink"
(
  mkdir -p "$(dirname "$bin_dest")"
  if [[ ! -L "$bin_dest" ]]; then
    ln -sf "$cli_dir/zion" "$bin_dest"
  fi
) >"$log_file" 2>&1 && _ok || _fail

# ── 3/3 bootstrap ───────────────────────────────────────────────────
_step 3 3 "Atualizando bootstrap"
src="$nixos_dir/zion/scripts/bootstrap-dashboard.sh"
(
  if [[ -f "$src" ]]; then
    install -m 755 "$src" "$nixos_dir/scripts/bootstrap.sh"
  fi
) >"$log_file" 2>&1 && _ok || _fail

printf "  ${_grn}${_bld}Feito!${_rst}\n"
