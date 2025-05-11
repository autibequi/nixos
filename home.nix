{ config, pkgs, home-manager, ... }:
{


  # User Accounts
  users.users.pedrinho = {
    isNormalUser = true;
    description = "pedrinho";
    extraGroups = [ "networkmanager" "wheel" "docker" "adbusers" ];
    shell = pkgs.zsh;
  };

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

    home.file = {
      #avatar
      ".face".source = ./assets/avatar.png;
    };
  };
}