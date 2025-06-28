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
    ./core/shell.nix
    # ./modules/battery.nix
    # ./modules/plymouth.nix
    # ./core/fonts.nix
    # ./core/kernel.nix
    # ./modules/nvidia.nix

    # Desktop Environments
    ./modules/gnome/core.nix
    # ./modules/cosmic.nix
    # ./modules/kde.nixs

    # Extra
    # ./modules/ai.nix
    # ./modules/asus.nix
    # ./modules/bluetooth.nix
    # ./modules/podman.nix
    # ./modules/howdy.nix
    # ./modules/flatpak.nix
    # ./modules/work.nix
  ];

  # Instalation
  options.diskUUIDs = {
    boot = lib.mkOption {
      description = "UUID of the boot partition";
      default = "/dev/disk/by-uuid/1F53-9115";
    };
    root = lib.mkOption {
      description = "UUID of the root partition";
      default = "/dev/disk/by-uuid/ee52cc58-f10d-4979-8244-4386302649c5";
    };
    swap = lib.mkOption {
      description = "UUID of the swap partition";
      default = "/dev/disk/by-uuid/17e5c565-c90c-4233-92c6-bb86adfed306";
    };
  };
}
