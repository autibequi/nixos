# Remove o symlink do zion de ~/.local/bin
BIN="${HOME}/.local/bin/zion"

if [ ! -e "$BIN" ] && [ ! -L "$BIN" ]; then
  echo "zion nao instalado em $BIN"
  exit 0
fi

if [ -L "$BIN" ]; then
  rm -f "$BIN"
  echo "symlink removido: $BIN"
elif [ -f "$BIN" ]; then
  rm -f "$BIN"
  echo "binario removido: $BIN"
fi

echo "zion desinstalado. Para reinstalar: cd ~/nixos/zion/bash && ./zion update"
