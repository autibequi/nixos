{ pkgs, ... }:
{
  imports = [
    ./sessions.nix
    ./portals.nix
    ./services.nix
    ./packages.nix
  ];

  # Configuração do Hyprland
  programs.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    xwayland.enable = true;
    withUWSM = true;
  };

  # Habilitar serviço para compilar schemas
  programs.dconf.enable = true;

  # GNOME Keyring - gerenciamento de secrets/senhas/SSH keys
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.hyprlock.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # HyprIdle
  services.hypridle.enable = true;

  # Register librsvg as gdk-pixbuf SVG loader (fixes SVG icons in rofi, waybar, etc)
  programs.gdk-pixbuf.modulePackages = [ pkgs.librsvg ];
}
