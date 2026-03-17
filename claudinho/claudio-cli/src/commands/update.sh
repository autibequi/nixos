# Regenera CLI (bashly) e instala/atualiza symlink em stow/.local/bin
cd "$claudio_compose_dir" && bashly generate
bin_dest="$claudio_nixos_dir/stow/.local/bin/claudio"
mkdir -p "$(dirname "$bin_dest")"
if [[ ! -L "$bin_dest" ]]; then
  ln -sf "$claudio_compose_dir/claudio" "$bin_dest"
  echo "[claudio update] symlink criado: $bin_dest"
else
  echo "[claudio update] claudio regenerado (symlink já existe)"
fi
