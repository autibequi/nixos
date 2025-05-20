{ config, pkgs, lib, ... }:
{
  imports = [
    ./debloat.nix
    ./extensions.nix
    ./home.nix
  ];

  # Enable Gnome
  services.xserver.desktopManager.gnome.enable = true; # Ativação base do Gnome

  services = {
    xserver = {
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

  environment.systemPackages = with pkgs; [
    # Gnome Stuff
    desktop-file-utils
    gnome-extension-manager # Ferramenta para gerenciar extensões

    # Utils
    pkgs.gnome-tweaks
  ];

  # terminal swap (since gnome-terminal is hardcoded as the default terminal)
  environment.etc."gnome-console".source = "${pkgs.ghostty}/bin/ghostty";

  # Global shell initialization commands, sourcing the external script
  environment.shellInit = builtins.readFile ../../dotfiles/init.sh;
} 