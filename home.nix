{ config, pkgs, home-manager, ... }:
{
  # User Accounts
  users.users.pedrinho = {
    isNormalUser = true;
    description = "pedrinho";
    extraGroups = [ "networkmanager" "wheel" "docker" "adbusers" ];
    packages = with pkgs; [
      # Thunderbird
    ];
    shell = pkgs.zsh;
  };

  # Home Manager
  home-manager.users."pedrinho" = { lib, ... }: {
    home.stateVersion = "24.11";

    # Git
    programs.git = {
        enable = true;
        userName  = "Pedro Correa";
        userEmail = "pedro.correa@estrategia.com";
    };

    # Gnome Basic Crap
    dconf.settings = {
      "org/gnome/desktop/peripherals/mouse" = { natural-scroll = true; };
      "org/gnome/mutter" = {
        experimental-features = ["scale-monitor-framebuffer"];
      };
    };

    home.file = {
      # Gnome Cecidilha Fix
      ".XCompose".text = ''
        # I shouldn't need to do this, but I do...
        # https://github.com/NixOS/nixpkgs/issues/239415
        include "%L"

        <dead_acute> <C> : "Ç"
        <dead_acute> <c> : "ç"
      '';

      #avatar
      ".face".source = ./assets/avatar.png;
    };
  };

}