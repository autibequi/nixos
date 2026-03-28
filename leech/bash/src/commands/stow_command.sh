# src/commands/stow_command.sh
# leech stow — deploy dotfiles no host via GNU stow.
# Dentro do container usa nsenter; no host roda direto.

local nixos_dir="${HOST_NIXOS_DIR:-$HOME/nixos}"

case "${args[action]:-restow}" in
  restow|re)
    echo "=== Stow restow (deploy dotfiles) ==="
    _leech_host_exec "cd $nixos_dir && stow -d stow -t \$HOME -R ."
    ;;
  delete|un|unstow)
    echo "=== Stow delete (remove symlinks) ==="
    _leech_host_exec "cd $nixos_dir && stow -d stow -t \$HOME -D ."
    ;;
  status|st)
    echo "=== Stow status ==="
    _leech_host_exec "cd $nixos_dir && stow -d stow -t \$HOME -n -R . 2>&1 | head -30"
    ;;
  *)
    echo "Ação desconhecida: ${args[action]}"
    echo "Uso: leech stow [restow|delete|status]"
    return 1
    ;;
esac

if [[ -n "${args[--reload]}" ]]; then
  echo "=== Recarregando Hyprland + Waybar ==="
  _leech_host_exec "hyprctl reload && pkill -SIGUSR2 waybar 2>/dev/null; echo 'reload ok'"
fi
