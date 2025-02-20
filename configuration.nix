{ config, pkgs, lib, ... } :

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  imports =
    [ 
      # Core
      ./hardware-configuration.nix
      ./kernel.nix
      ./home.nix
      ./services.nix
      ./programs.nix
      ./packages.nix

      # DE Picker
      # ./desktop-enviroments/kde.nix
      ./desktop-enviroments/gnome.nix
      # ./desktop-enviroments/cosmic.nix

      # Optionals
      ./work.nix

      # Testing :|
      # ./howdy.nix
      # ./ai.nix # heeeavy

      # Failed :(
      # ./flatpak.nix
      # ./battery.nix
    ];

  # System State Version
  system.stateVersion = "25.05";

  # NIXOS STUFF
  # Garbage Collection
  nix.gc = {
    automatic = true;
    randomizedDelaySec = "14m";
    options = "--delete-older-than 10d";
  };

  # Unholy packages
  nixpkgs.config.allowUnfree = true;

  # Environment Variables
  environment.sessionVariables = {
    GTK_IM_MODULE = "cedilla";
    QT_IM_MODULE = "cedilla";

    # Wayland Growth Pains
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    OZONE_PLATFORM = "wayland";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";

    # QT Scaling for Stremio
    QT_AUTO_SCREEN_SCALE_FACTOR="1";
  };

  # Networking
  networking = {
    hostName = "nomad"; 
    useDHCP = lib.mkDefault true;
    extraHosts = ''
      127.0.0.1 local.estrategia-sandbox.com.br 
    '';

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
    monospace = [ "fira-code" ];
    sansSerif = [ "noto-sans" ];
    serif = [ "noto-serif" ];
  };

  # XDG Portal
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # Docker
  virtualisation.docker.enable = true;
}
