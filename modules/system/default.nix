{ ... }:
{
  # System: núcleo do sistema (nix, locale, usuários, rede, performance,
  # serviços de base, shell, fontes, programas e pacotes gerais).
  imports = [
    ./base.nix # stateVersion, plataforma, env vars, tmpfs
    ./nix.nix # nix settings, GC, auto-upgrade, nix-ld, appimage
    ./locale.nix # teclado, timezone, i18n
    ./users.nix # contas e grupos
    ./networking.nix # hostname, NetworkManager, tailscale, ssh, firewall
    ./performance.nix # oomd, journald, slices, limites, timeouts
    ./services.nix # printing, upower, udisks, gvfs, fwupd, modemmanager
    ./shell.nix # zsh + toolchain CLI
    ./fonts.nix
    ./programs.nix # nano off, direnv, starship, waydroid
    ./packages.nix # pacotes de sistema gerais
    ./packages-extra.nix # catálogo opt-in (tudo comentado; descomente p/ ativar)
  ];
}
