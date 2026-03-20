# Regenera CLI, instala symlink e atualiza bootstrap
cli_dir="$zion_compose_dir"
nixos_dir="$zion_nixos_dir"
bin_dest="${HOME}/.local/bin/zion"
log_file="$(mktemp /tmp/zion-update-XXXXXX.log)"
trap 'rm -f "$log_file"' EXIT

_run_step() {
  local n="$1"
  local total="$2"
  local label="$3"
  shift 3

  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local idx=0

  "$@" >"$log_file" 2>&1 &
  local pid=$!

  while kill -0 "$pid" 2>/dev/null; do
    printf "\r  \033[2m[%s/%s]\033[0m %s \033[33m%s\033[0m" \
      "$n" "$total" "$label" "${frames[$idx]}"
    idx=$(( (idx + 1) % 10 ))
    sleep 0.08
  done

  wait "$pid"
  local rc=$?

  if [[ $rc -eq 0 ]]; then
    printf "\r  \033[2m[%s/%s]\033[0m %s \033[32m✓\033[0m\n" "$n" "$total" "$label"
  else
    printf "\r  \033[2m[%s/%s]\033[0m %s \033[31m✗\033[0m\n" "$n" "$total" "$label"
    cat "$log_file" >&2
    exit 1
  fi
}

_gen() {
  cd "$cli_dir" && LANG=en_US.UTF-8 RUBYOPT="-E utf-8" bashly generate
}

_symlink() {
  local old_dest="$nixos_dir/stow/.local/bin/zion"
  [[ -L "$old_dest" ]] && rm -f "$old_dest"
  mkdir -p "$(dirname "$bin_dest")"
  ln -sf "$cli_dir/zion" "$bin_dest"
}

_bootstrap() {
  local src="$nixos_dir/zion/scripts/bootstrap-dashboard.sh"
  if [[ -f "$src" ]]; then
    install -m 755 "$src" "$nixos_dir/scripts/bootstrap.sh"
  fi
}

printf "\033[1mAtualizando zion...\033[0m\n"
_run_step 1 3 "Gerando CLI"           _gen
_run_step 2 3 "Instalando symlink"    _symlink
_run_step 3 3 "Atualizando bootstrap" _bootstrap
printf "  \033[32m\033[1mFeito!\033[0m\n"
