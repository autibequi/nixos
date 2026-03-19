zion_load_config
WS="${ZION_NIXOS_DIR:-$HOME/nixos}"
FLAG="$WS/.ephemeral/debug-mode"
mkdir -p "$WS/.ephemeral"

if [ -f "$FLAG" ]; then
  rm "$FLAG"
  echo "[zion debug] OFF — testing overrides desativados"

else
  touch "$FLAG"
  echo "[zion debug] ON — testing overrides ativos na proxima sessao"
fi
