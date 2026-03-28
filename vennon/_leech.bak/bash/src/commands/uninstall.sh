# Remove o symlink do leech de ~/.local/bin
BIN="${HOME}/.local/bin/leech"

if [ ! -e "$BIN" ] && [ ! -L "$BIN" ]; then
  echo "leech nao instalado em $BIN"
  exit 0
fi

if [ -L "$BIN" ]; then
  rm -f "$BIN"
  echo "symlink removido: $BIN"
elif [ -f "$BIN" ]; then
  rm -f "$BIN"
  echo "binario removido: $BIN"
fi

echo "leech desinstalado. Para reinstalar: cd ~/nixos/leech/bash && ./leech update"
