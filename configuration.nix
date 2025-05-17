{ config, pkgs, lib, ... } :

{
  # System State Version
  system.stateVersion = "25.05";

  imports =
    [ 
      # Substituters ans stuff
      ./nix.nix

      # Core
      ./core/hardware.nix
      ./core/kernel.nix
      ./core/home.nix
      ./core/services.nix
      ./core/programs.nix
      ./core/packages.nix

      # Modules
      ./modules/battery.nix
      ./modules/bluetooth.nix
      ./modules/nvidia.nix
      ./modules/plymouth.nix

      # Optional Modules
      ./modules/work.nix

      # DE Picker
      ./desktop-envs/gnome/de.nix
      # ./desktop-envs/cosmic.nix
      # ./desktop-envs/kde.nix

      # Testing Modules
      # ./modules/howdy.nix
      # ./modules/flatpak.nix
      # ./modules/ai.nix # heeeavy
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
    monospace = [ "FiraCode Nerd Font Mono Bold" "Fira Code Bold" "Liberation Mono Bold" "Noto Sans Mono Bold" ];
    sansSerif = [ "Noto Sans Bold" "Liberation Sans Bold" "Fira Sans Bold" ];
    serif = [ "Noto Serif Bold" "Liberation Serif Bold" "Fira Serif Bold" ];
  };

  # XDG Portal
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
}
