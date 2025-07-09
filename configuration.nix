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
    ./modules/battery.nix
    ./modules/bluetooth.nix
    ./modules/plymouth.nix
    ./core/fonts.nix
    ./core/kernel.nix

    # Hardware specific
    ./modules/asus.nix
    # ./modules/nvidia.nix

    # Desktop Environments
    ./modules/hyprland.nix
    # ./modules/gnome/core.nix
    # ./modules/cosmic.nix
    # ./modules/kde.nixs

    # Extra
    ./modules/ai.nix
    ./modules/asus.nix
    ./modules/bluetooth.nix
    # ./modules/podman.nix
    # ./modules/howdy.nix
    ./modules/flatpak.nix
    # ./modules/work.nix
  ];

  # Instalation
  options.diskUUIDs = {
    boot = lib.mkOption {
      description = "Boot partition";
      default = "/dev/disk/by-uuid/6B74-DC9D";
    };
    root = lib.mkOption {
      description = "Toot partition";
      default = "/dev/disk/by-uuid/4265d4f9-7f7b-4ebf-a3b4-a3406c3c0955";
    };
    swap = lib.mkOption {
      description = "Swap partition";
      default = "/dev/disk/by-uuid/c824afe8-bf19-4f7f-9876-5fcff8c93593";
    };
  };
}
