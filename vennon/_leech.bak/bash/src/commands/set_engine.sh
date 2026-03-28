# Define o engine padrão em ~/.leech
engine_arg="${args['engine']:-}"
config_file="${LEECH_CONFIG:-$HOME/.leech}"

case "$engine_arg" in
  claude|opencode|cursor) ;;
  *)
    echo "leech set: engine inválido '$engine_arg' (use: claude | opencode | cursor)" >&2
    exit 1
    ;;
esac

if [[ ! -f "$config_file" ]]; then
  echo "leech set: $config_file não encontrado — rode 'leech init' primeiro" >&2
  exit 1
fi

# Atualiza ou insere engine= no ~/.leech
if grep -q "^engine=" "$config_file"; then
  sed -i "s|^engine=.*|engine=${engine_arg}|" "$config_file"
else
  echo "engine=${engine_arg}" >> "$config_file"
fi

echo "[leech set] engine=${engine_arg} → $config_file"
