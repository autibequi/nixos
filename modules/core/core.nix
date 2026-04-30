{
  lib,
  pkgs,
  ...
}:
{
  # Define a versão do sistema para evitar avisos de "outdated channel"
  system.stateVersion = "25.05";

  # Global shell initialization commands, sourcing the external script
  # environment.shellInit = builtins.readFile ../../scripts/init.sh;

  services.xserver.xkb = {
    layout = "us";
    variant = "alt-intl";
  };

  # are we ARM yet?
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Graphical Driver List
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Bootloader
  boot.loader.limine.enable = true;
  boot.loader.limine.efiSupport = true;
  boot.loader.limine.maxGenerations = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 3; # segundos antes de auto-boot (0 = imediato, sem menu)

  # Tema Catppuccin Mocha (mesmo do CachyOS)
  boot.loader.limine.style = {
    wallpapers = [ pkgs.nixos-artwork.wallpapers.catppuccin-mocha.gnomeFilePath ];
    wallpaperStyle = "stretched";
    backdrop = "1e1e2e";
    graphicalTerminal = {
      foreground = "cdd6f4";
      background = "801e1e2e"; # TTRRGGBB — 80 = ~50% transparente sobre o wallpaper
      brightForeground = "cdd6f4";
      brightBackground = "801e1e2e";
      palette = "45475a;f38ba8;a6e3a1;f9e2af;89b4fa;cba4f7;89dceb;bac2de";
      brightPalette = "585b70;f38ba8;a6e3a1;f9e2af;89b4fa;cba4f7;89dceb;cdd6f4";
      margin = 10;
      marginGradient = 4;
    };
    interface = {
      brandingColor = 5; # mauve — cor 5 da palette acima (cba4f7)
    };
  };

  # Environment Variables
  environment.sessionVariables = {
    # Wayland Pains
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    OZONE_PLATFORM = "wayland";
    # ELECTRON_OZONE_PLATFORM_HINT — definido como "auto" em hyprland.conf (via UWSM env)
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    # Qt6 Wayland backend — sem isso Qt6 apps (ex: hyprpolkitagent) não conseguem
    # carregar nenhum QPA e crasham com SIGABRT em init_platform(), derrubando a sessão.
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
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

  # /tmp em RAM — com 46GB+ RAM é gratuito e acelera builds/temp
  boot.tmp.useTmpfs = true;
  boot.tmp.tmpfsSize = "8G";

  # Add local bin to PATH
  environment.localBinInPath = true;

  environment.variables.EDITOR = "vim";
  environment.variables.VISUAL = "vim";

  # Limites para Podman rootless com múltiplos containers simultâneos
  security.pam.loginLimits = [
    { domain = "*"; type = "soft"; item = "nofile"; value = "65536"; }
    { domain = "*"; type = "hard"; item = "nofile"; value = "65536"; }
  ];

  boot.kernel.sysctl = {
    "fs.inotify.max_user_instances" = 8192;
    "fs.inotify.max_user_watches"   = 524288;
    "fs.file-max"                   = 1048576;
  };

  users.defaultUserShell = pkgs.zsh;

  users.groups.docker = { };

  # User Accounts
  users.users.pedrinho = {
    isNormalUser = true;
    description = "pedrinho";
    extraGroups = [
      "adbusers"
      "docker"
      "podman" # socket em /run/podman/podman.sock (virtualisation.podman.dockerSocket)
      "hidraw"
      "input"
      "networkmanager"
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
