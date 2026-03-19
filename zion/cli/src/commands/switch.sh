# zion switch — aplica configuração NixOS no host.
# Dentro do container usa nsenter; no host roda direto.

local nixos_dir="${HOST_NIXOS_DIR:-$HOME/nixos}"
local mode="${args[mode]:-switch}"

case "$mode" in
  switch)
    echo "=== NixOS switch ==="
    _zion_host_exec "cd $nixos_dir && nh os switch ."
    ;;
  test)
    echo "=== NixOS test (build sem ativar) ==="
    _zion_host_exec "cd $nixos_dir && nh os test ."
    ;;
  boot)
    echo "=== NixOS boot (ativa no próximo reboot) ==="
    _zion_host_exec "cd $nixos_dir && nh os boot ."
    ;;
  build)
    echo "=== NixOS build (só compila) ==="
    _zion_host_exec "cd $nixos_dir && nh os build ."
    ;;
  *)
    echo "Modo desconhecido: $mode"
    echo "Uso: zion switch [switch|test|boot|build]"
    return 1
    ;;
esac
