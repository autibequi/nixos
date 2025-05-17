{ config, pkgs, lib, ... }:
{
  imports = [
    ./debloat.nix
    ./extensions.nix
    ./home.nix
  ];

  # Enable Gnome
  service.desktopManager.gnome.enable = true; # Ativação base do Gnome

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

  # Power
  # Restart Extensions 'cos gnome stuff 💅
  powerManagement.resumeCommands =
  ''
    gsettings set org.gnome.shell disable-user-extensions true
    gsettings set org.gnome.shell disable-user-extensions false
  '';
} 