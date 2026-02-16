# Instalation
# Create a copy of this file name hardware.nix with such inside:
# In a fresh start this info can be retrieve by:
#
# cat /etc/nixos/hardware-configuration.nix | grep -B 3 "device ="
#
{ lib, ... }:
{
  imports = [
    # Hardware Specific
    ./modules/asus.nix
    ./modules/nvidia.nix

    # Laptop Modules
    # ./modules/tlp.nix
    ./modules/battery.nix

    # Desktop Enviroments
    ./modules/hyprland.nix
    # ./modules/gnome/core.nix
    # ./modules/cosmic.nix
    # ./modules/kde.nixs

    # Other Modules
    ./modules/work.nix

    # Testing
    # ./modules/howdy.nix
  ];

  options.diskUUIDs = {
    boot = lib.mkOption {
      description = "Boot partition";
      default = "/dev/disk/by-uuid/6B74-DC9D";
    };
    root = lib.mkOption {
      description = "Root partition";
      default = "/dev/disk/by-uuid/4265d4f9-7f7b-4ebf-a3b4-a3406c3c0955";
    };
    swap = lib.mkOption {
      description = "Swap partition";
      default = "/dev/disk/by-uuid/c824afe8-bf19-4f7f-9876-5fcff8c93593";
    };
  };
}
