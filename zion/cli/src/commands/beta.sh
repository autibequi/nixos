zion_load_config
WS="${ZION_NIXOS_DIR:-$HOME/nixos}"
FLAG="$WS/.ephemeral/beta-mode"
mkdir -p "$WS/.ephemeral"

if [ -f "$FLAG" ]; then
  rm "$FLAG"
  echo "[zion beta] OFF — beta overrides desativados"

else
  touch "$FLAG"
  echo "[zion beta] ON — beta overrides ativos na proxima sessao"
fi
