{ config, pkgs, lib, ... } :

{
  # System State Version
  system.stateVersion = "25.05";

  imports =
    [ 
      # Core
      ./nix.nix
      ./hardware-configuration.nix
      ./kernel.nix
      ./home.nix
      ./services.nix
      ./programs.nix
      ./packages.nix
      ./nvidia.nix
      ./bluetooth.nix
      ./battery.nix
      ./plymouth.nix

      # DE Picker
      ./desktop-enviroments/gnome.nix
      # ./desktop-enviroments/cosmic.nix
      # ./desktop-enviroments/kde.nix

      # Optionals
      ./work.nix

      # Testing
      # ./howdy.nix
      # ./flatpak.nix
      # ./ai.nix # heeeavy
    ];

  # Networking
  networking = {
    hostName = "nomad"; 
    useDHCP = lib.mkDefault true;
    networkmanager = {
      enable = true;
    };
  };

  # Time and Locale
  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  # Fonts
  fonts = {
    fontconfig.enable = true;
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
    ];
  };

  fonts.fontconfig.defaultFonts = {
    monospace = [ "FiraCode Nerd Font" "Fira Code" ];
    sansSerif = [ "Noto Sans" "Liberation Sans" ];
    serif = [ "Noto Serif" "Liberation Serif" ];
  };

  # XDG Portal
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
}
