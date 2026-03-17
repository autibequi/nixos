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
