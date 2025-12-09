{
  lib,
  pkgs,
  ...
}:
{
  # Global shell initialization commands, sourcing the external script
  environment.shellInit = builtins.readFile ../../scripts/init.sh;

  services.xserver.xkb = {
    layout = "us";
    variant = "alt-intl";
  };

  # are we ARM yet?
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Graphical Driver List
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Environment Variables
  environment.sessionVariables = {
    # Wayland Pains
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    OZONE_PLATFORM = "wayland";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    _JAVA_AWT_WM_NONREPARENTING = 1;
  };

  # Hardware
  # Stallman would be very sad with me...
  hardware = {
    enableAllFirmware = true;
    enableAllHardware = true;
    enableRedistributableFirmware = true;
    amdgpu.initrd.enable = true;
    cpu.amd.updateMicrocode = true;
  };

  # Add local bin to PATH
  environment.localBinInPath = true;

  users.defaultUserShell = pkgs.zsh;

  users.groups.docker = { }; #

  # User Accounts
  users.users.pedrinho = {
    isNormalUser = true;
    description = "pedrinho";
    extraGroups = [
      "adbusers"
      "docker"
      "hidraw"
      "input"
      "networkmanager"
      "podman"
      "wheel"
    ];
    shell = pkgs.zsh;
  };

  # Networking
  networking = {
    hostName = "nomad";
    networkmanager.enable = true;
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
}
