# Regenera CLI (bashly) e instala/atualiza symlink em stow/.local/bin
cd "$zion_compose_dir" && bashly generate
bin_dest="$zion_nixos_dir/stow/.local/bin/zion"
mkdir -p "$(dirname "$bin_dest")"
if [[ ! -L "$bin_dest" ]]; then
  ln -sf "$zion_compose_dir/zion" "$bin_dest"
  echo "[zion update] symlink criado: $bin_dest"
else
  echo "[zion update] zion regenerado (symlink já existe)"
fi
