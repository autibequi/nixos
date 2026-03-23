# Regenera CLI, instala symlink e atualiza bootstrap
cli_dir="$leech_bash_dir"
nixos_dir="$leech_nixos_dir"
bin_bash="${HOME}/.local/bin/leech-bash"
bin_rust="${HOME}/.local/bin/leech"
log_file="$(mktemp /tmp/leech-update-XXXXXX.log)"
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
  bash -n "$cli_dir/leech" || {
    echo "bashly gerou script invalido (bash -n falhou). Nao sobrescrevendo ~/.local/bin/leech." >&2
    exit 1
  }
}

_symlink() {
  local old_dest="$nixos_dir/stow/.local/bin/leech"
  [[ -L "$old_dest" ]] && rm -f "$old_dest"
  mkdir -p "$(dirname "$bin_bash")"
  rm -f "$bin_bash"
  ln -sf "$cli_dir/leech" "$bin_bash"
}

_rust() {
  local rust_dir="$nixos_dir/leech/rust"
  [[ -d "$rust_dir" ]] || return 0
  if command -v cargo &>/dev/null; then
    cargo build --release -p leech-cli || exit 1
  else
    nix-shell -p rustc -p cargo --run 'cargo build --release -p leech-cli' || exit 1
  fi
  rm -f "$bin_rust"
  cp "$rust_dir/target/release/leech" "$bin_rust"
}

_bootstrap() {
  local src="$nixos_dir/leech/self/scripts/bootstrap-dashboard.sh"
  if [[ -f "$src" ]]; then
    install -m 755 "$src" "$nixos_dir/scripts/bootstrap.sh"
  fi
}

printf "\033[1mAtualizando leech...\033[0m\n"
_run_step 1 4 "Gerando bash CLI"        _gen
_run_step 2 4 "Instalando bash CLI"     _symlink
_run_step 3 4 "Atualizando bootstrap"   _bootstrap
_run_step 4 4 "Building leech (rust)"   _rust
printf "  \033[32m\033[1mFeito!\033[0m\n"
