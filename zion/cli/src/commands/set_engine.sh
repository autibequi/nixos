# Define o engine padrão em ~/.zion
engine_arg="${args['engine']:-}"
config_file="${ZION_CONFIG:-$HOME/.zion}"

case "$engine_arg" in
  claude|opencode|cursor) ;;
  *)
    echo "zion set: engine inválido '$engine_arg' (use: claude | opencode | cursor)" >&2
    exit 1
    ;;
esac

if [[ ! -f "$config_file" ]]; then
  echo "zion set: $config_file não encontrado — rode 'zion init' primeiro" >&2
  exit 1
fi

# Atualiza ou insere engine= no ~/.zion
if grep -q "^engine=" "$config_file"; then
  sed -i "s|^engine=.*|engine=${engine_arg}|" "$config_file"
else
  echo "engine=${engine_arg}" >> "$config_file"
fi

echo "[zion set] engine=${engine_arg} → $config_file"
