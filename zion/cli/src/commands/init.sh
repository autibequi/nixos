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

# Garante PATH no ~/.zshrc e ~/.bashrc para zion funcionar (zsh e bash)
bin_dir="$zion_nixos_dir/stow/.local/bin"
for rc in "${ZDOTDIR:-$HOME}/.zshrc" "$HOME/.bashrc"; do
  [[ -d "$bin_dir" ]] || continue
  [[ -n "$rc" ]] || continue
  [[ -f "$rc" ]] || touch "$rc"
  [[ -w "$rc" ]] || continue
  added=""
  if ! grep -q "stow/.local/bin" "$rc" 2>/dev/null; then
    echo "" >> "$rc"
    echo "# Zion CLI (adicionado por zion init)" >> "$rc"
    printf 'export PATH="%s:$PATH"\n' "$bin_dir" >> "$rc"
    added="PATH "
  fi
  [[ -n "$added" ]] && echo "[zion init] ${added}em $rc — rode: source $rc"
done
