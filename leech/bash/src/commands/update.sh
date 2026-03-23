# Regenera CLI (leech + zion), instala symlinks, bootstrap e Rust
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

# Helper: roda bashly generate em um diretório (usa gem, nix-shell ou sistema)
_bashly_run() {
  local dir="$1"
  [[ -d "$dir" && -f "$dir/src/bashly.yml" ]] || return 0
  if command -v bashly &>/dev/null; then
    (cd "$dir" && LANG=en_US.UTF-8 RUBYOPT="-E utf-8" bashly generate)
  elif command -v nix-shell &>/dev/null; then
    nix-shell -p bashly --run "cd '$dir' && LANG=en_US.UTF-8 RUBYOPT='-E utf-8' bashly generate"
  fi
}

_gen_leech() {
  _bashly_run "$cli_dir"
  bash -n "$cli_dir/leech" || {
    echo "bashly gerou script invalido (bash -n falhou)." >&2
    exit 1
  }
}

_gen_zion() {
  # Fonte do zion CLI (quando disponível no repo)
  local zion_src_dir="$nixos_dir/self/containers/zion"
  _bashly_run "$zion_src_dir"
  return 0  # best-effort
}

_symlinks() {
  # leech-bash
  local old_leech="$nixos_dir/stow/.local/bin/leech"
  [[ -L "$old_leech" ]] && rm -f "$old_leech"
  mkdir -p "$(dirname "$bin_bash")"
  rm -f "$bin_bash"
  ln -sf "$cli_dir/leech" "$bin_bash"
  # zion → prefere self/containers/zion/zion, fallback leech/bash/zion
  local bin_zion="${HOME}/.local/bin/zion"
  local old_zion="$nixos_dir/stow/.local/bin/zion"
  [[ -L "$old_zion" ]] && rm -f "$old_zion"
  local zion_bin="$nixos_dir/self/containers/zion/zion"
  [[ -f "$zion_bin" ]] || zion_bin="$cli_dir/zion"
  [[ -f "$zion_bin" ]] && ln -sf "$zion_bin" "$bin_zion"
}

_rust() {
  local rust_dir="$nixos_dir/leech/rust"
  [[ -d "$rust_dir" ]] || return 0
  if command -v cargo &>/dev/null; then
    cd "$rust_dir" && cargo build --release -p leech-cli || exit 1
  elif command -v nix-shell &>/dev/null; then
    nix-shell -p rustc -p cargo --run \
      "cd '$rust_dir' && cargo build --release -p leech-cli" || exit 1
  else
    echo "cargo nao encontrado — instale rust para rebuildar o binario leech" >&2
    return 0
  fi
  rm -f "$bin_rust"
  cp "$rust_dir/target/release/leech" "$bin_rust"
}

_bootstrap() {
  local src="$nixos_dir/leech/self/scripts/bootstrap-dashboard.sh"
  [[ -f "$src" ]] && install -m 755 "$src" "$nixos_dir/scripts/bootstrap.sh"
  return 0
}

printf "\033[1mAtualizando leech...\033[0m\n"
_run_step 1 5 "Gerando leech bash CLI"  _gen_leech
_run_step 2 5 "Gerando zion bash CLI"   _gen_zion
_run_step 3 5 "Instalando symlinks"     _symlinks
_run_step 4 5 "Atualizando bootstrap"   _bootstrap
_run_step 5 5 "Building leech (rust)"   _rust
printf "  \033[32m\033[1mFeito!\033[0m\n"
