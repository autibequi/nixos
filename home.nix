{ config, pkgs, home-manager, ... }:
{
  # Environment Variables
  environment.sessionVariables = {
    # Wayland Pains
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    OZONE_PLATFORM = "wayland";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    QT_AUTO_SCREEN_SCALE_FACTOR="1";
    NIXPKGS_ALLOW_INSECURE=1;
  };

  # User Accounts
  users.users.pedrinho = {
    isNormalUser = true;
    description = "pedrinho";
    extraGroups = [ "networkmanager" "wheel" "docker" "adbusers" ];
    shell = pkgs.zsh;
  };

  # avoid file colisions
  home-manager.backupFileExtension = "hm-backup";

  # Home Manager
  home-manager.users."pedrinho" = { lib, ... }: {
    home.stateVersion = "25.05";

    # Disable annoying different nix/home version while migrating
    home.enableNixpkgsReleaseCheck = false;

    # Git
    programs.git = {
        enable = true;
        userName  = "Pedro Correa";
        userEmail = "pedro.correa@estrategia.com";
    };
    # Banana cursor theme
    home.pointerCursor = {
      name = "Banana";
      package = pkgs.banana-cursor;
      size = 40;
    };
    home.file = {
      ".face".source = ./assets/avatar.png; # avatar
    };

    # TODO: Not beeing copied
    # dotfiles
    home.file = {
      ".config/ghosty/config".source = ./dotfiles/ghostty.conf;
      ".config/atuin/config.toml".source = ./dotfiles/atuin.conf;
    };
  };

  # not working due unstable channel
  # stylix.enable = true;
}