{ pkgs, ... }:
{
  imports = [
    ./packages.nix
    ./extensions.nix
    ./home.nix
  ];

  services = {
    xserver = {
      desktopManager.gnome.enable = true;
      enable = true;
      displayManager.gdm = {
        enable = true;
        wayland = true;
      };
      xkb = {
        layout = "us";
        variant = "alt-intl";
      };
    };
  };

  # terminal swap (since gnome-terminal is hardcoded as the default terminal)
  environment.etc."gnome-console".source = "${pkgs.ghostty}/bin/ghostty";

  # Global shell initialization commands, sourcing the external script
  environment.shellInit = builtins.readFile ../../dotfiles/init.sh;
}
