{
  lib,
  ...
}:
{
  # Importa Setup do Usuario
  imports = [
    # Core
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
    ./modules/battery.nix
    ./modules/bluetooth.nix
    ./modules/plymouth.nix
    ./modules/flatpak.nix
    ./modules/ai.nix
    ./modules/hibernate.nix
    # ./modules/podman.nix
    # ./modules/tlp.nix
    # ./modules/battery.nix

    # Hardware specific
    ./modules/asus.nix
    # ./modules/nvidia.nix

    # Desktop Environments
    ./modules/hyprland.nix
    # ./modules/gnome/core.nix
    # ./modules/cosmic.nix
    # ./modules/kde.nixs

    # Extra
    # ./modules/work.nix
  ];

  # Instalation
  options.diskUUIDs = {
    boot = lib.mkOption {
      description = "Boot partition";
      default = "/dev/disk/by-uuid/";
    };
    root = lib.mkOption {
      description = "Root partition";
      default = "/dev/disk/by-uuid/";
    };
    swap = lib.mkOption {
      description = "Swap partition";
      default = "/dev/disk/by-uuid/";
    };
  };
}
