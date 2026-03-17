# Cria ~/.zion a partir de config.example
dest="${ZION_CONFIG:-$HOME/.zion}"
src="$zion_compose_dir/config.example"
if [[ ! -f "$src" ]]; then
  echo "zion init: config.example não encontrado em $src" >&2
  exit 1
fi
if [[ -f "$dest" ]] && [[ -z "${args['--force']:-${flag_force:-}}" ]]; then
  echo "[zion init] $dest já existe (use --force para sobrescrever)"
  exit 0
fi
cp "$src" "$dest"
chmod 600 "$dest"
echo "[zion init] Criado $dest — edite e preencha engine=, GH_TOKEN=, ANTHROPIC_API_KEY="

# Garante PATH e alias no ~/.zshrc para zion e claudio funcionarem
bin_dir="$zion_nixos_dir/stow/.local/bin"
zshrc="${ZDOTDIR:-$HOME}/.zshrc"
if [[ -d "$bin_dir" ]] && [[ -n "$zshrc" ]]; then
  [[ -f "$zshrc" ]] || touch "$zshrc"
  if [[ -w "$zshrc" ]]; then
    added=""
    if ! grep -q "stow/.local/bin" "$zshrc" 2>/dev/null; then
      echo "" >> "$zshrc"
      echo "# Zion CLI (adicionado por zion init)" >> "$zshrc"
      printf 'export PATH="%s:$PATH"\n' "$bin_dir" >> "$zshrc"
      added="PATH "
    fi
    if ! grep -q "alias claudio=zion" "$zshrc" 2>/dev/null; then
      echo "alias claudio=zion" >> "$zshrc"
      added="${added}alias "
    fi
    [[ -n "$added" ]] && echo "[zion init] ${added}adicionados em $zshrc — rode: source $zshrc"
  fi
fi
