# Regenera CLI (bashly), instala/atualiza symlink e atualiza scripts/bootstrap.sh (mounts em /workspace/nixos)
cd "$zion_compose_dir" && bashly generate
bin_dest="$zion_nixos_dir/stow/.local/bin/zion"
mkdir -p "$(dirname "$bin_dest")"
if [[ ! -L "$bin_dest" ]]; then
  ln -sf "$zion_compose_dir/zion" "$bin_dest"
  echo "[zion update] symlink criado: $bin_dest"
else
  echo "[zion update] zion regenerado (symlink já existe)"
fi
# Atualiza scripts/bootstrap.sh a partir da fonte (mounts sob /workspace)
if [[ -f "$zion_nixos_dir/zion/scripts/bootstrap-dashboard.sh" ]]; then
  mkdir -p "$zion_nixos_dir/scripts"
  install -m 755 "$zion_nixos_dir/zion/scripts/bootstrap-dashboard.sh" "$zion_nixos_dir/scripts/bootstrap.sh"
  echo "[zion update] scripts/bootstrap.sh atualizado"
fi
