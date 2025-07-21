{
  lib,
  ...
}:
{
  # Importa Setup do Usuario
  imports = [
    # Core Modules
    ./core/nix.nix
    ./core/hardware.nix
    ./core/core.nix
    ./core/home.nix
    ./core/services.nix
    ./core/programs.nix
    ./core/packages.nix
    ./core/fonts.nix
    ./core/shell.nix
    ./core/kernel.nix

    # Stable Modules
    ./modules/battery.nix
    ./modules/bluetooth.nix
    ./modules/plymouth.nix
    ./modules/ai.nix
    ./modules/hibernate.nix
    ./modules/steam.nix
    ./modules/podman.nix

    # Laptop Modules
    # ./modules/tlp.nix
    # ./modules/battery.nix

    # Hardware
    # ./modules/asus.nix
    #./modules/nvidia.nix

    # Desktop Enviroments
    ./modules/hyprland/hyprland.nix
    # ./modules/gnome/core.nix
    # ./modules/cosmic.nix
    # ./modules/kde.nixs

    # Custom Modules (Packages not well supported yet by nixpkgs)
    ./modules/custom/flatpak.nix
    # ./modules/custom/howdy.nix

    # Other Modules
    # ./modules/work.nix
  ];

  # Instalation
  options.diskUUIDs = {
    boot = lib.mkOption {
      description = "Boot partition";
      default = "/dev/disk/by-uuid/";
    };
    root = lib.mkOption {
      description = "Toot partition";
      default = "/dev/disk/by-uuid/";
    };
    swap = lib.mkOption {
      description = "Swap partition";
      default = "/dev/disk/by-uuid/";
    };
  };
}
