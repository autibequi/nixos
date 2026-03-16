# Cria ~/.claudio a partir de config.example
dest="${CLAUDIO_CONFIG:-$HOME/.claudio}"
src="$claudio_compose_dir/config.example"
if [[ ! -f "$src" ]]; then
  echo "claudio init: config.example não encontrado em $src" >&2
  exit 1
fi
if [[ -f "$dest" ]] && [[ -z "${args['--force']:-${flag_force:-}}" ]]; then
  echo "[claudio init] $dest já existe (use --force para sobrescrever)"
  exit 0
fi
cp "$src" "$dest"
chmod 600 "$dest"
echo "[claudio init] Criado $dest — edite e preencha engine=, GH_TOKEN=, ANTHROPIC_API_KEY="
