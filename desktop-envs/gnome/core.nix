{ pkgs, ... }:
{
  imports = [
    ./packages.nix
    ./extensions.nix
    ./home.nix
  ];

  services = {
    desktopManager.gnome.enable = true;
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
  };

  # terminal swap (since gnome-terminal is hardcoded as the default terminal)
  environment.etc."gnome-console".source = "${pkgs.ghostty}/bin/ghostty";

  # Global shell initialization commands, sourcing the external script
  environment.shellInit = builtins.readFile ../../dotfiles/init.sh;
}
