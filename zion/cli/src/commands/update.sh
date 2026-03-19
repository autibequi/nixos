# Regenera CLI (bashly), instala/atualiza symlink e atualiza scripts/bootstrap.sh
# Delega ao Justfile se just estiver disponível; fallback para lógica inline.
if command -v just &>/dev/null && [[ -f "$zion_compose_dir/Justfile" ]]; then
  cd "$zion_compose_dir" && just install
else
  # fallback: lógica original
  cd "$zion_compose_dir" && LANG=en_US.UTF-8 RUBYOPT="-E utf-8" bashly generate
  bin_dest="$zion_nixos_dir/stow/.local/bin/zion"
  mkdir -p "$(dirname "$bin_dest")"
  if [[ ! -L "$bin_dest" ]]; then
    ln -sf "$zion_compose_dir/zion" "$bin_dest"
    echo "[zion update] symlink criado: $bin_dest"
  else
    echo "[zion update] zion regenerado (symlink ja existe)"
  fi
  if [[ -f "$zion_nixos_dir/zion/scripts/bootstrap-dashboard.sh" ]]; then
    mkdir -p "$zion_nixos_dir/scripts"
    install -m 755 "$zion_nixos_dir/zion/scripts/bootstrap-dashboard.sh" "$zion_nixos_dir/scripts/bootstrap.sh"
    echo "[zion update] scripts/bootstrap.sh atualizado"
  fi
fi
