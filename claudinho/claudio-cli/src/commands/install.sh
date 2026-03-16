# Regenera CLI (bashly) e instala symlink em stow/.local/bin
cd "$claudio_compose_dir" && bashly generate
bin_dest="$claudio_nixos_dir/stow/.local/bin/claudio"
mkdir -p "$(dirname "$bin_dest")"
if [[ ! -L "$bin_dest" ]]; then
  ln -sf "$claudio_compose_dir/../claudio" "$bin_dest"
  echo "[claudio install] symlink criado: $bin_dest"
else
  echo "[claudio install] claudio regenerado (symlink já existe)"
fi
