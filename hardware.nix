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
    # ./modules/asus.nix
    # ./modules/nvidia.nix
    ./modules/logitech-mouse.nix

    # Laptop Modules
    # ./modules/tlp.nix
    # ./modules/battery.nix

    # Desktop Enviroments
    ./modules/hyprland.nix
    # ./modules/gnome/core.nix
    # ./modules/cosmic.nix
    # ./modules/kde.nixs

    # Other Modules
    # ./modules/work.nix

    # Testing
    # ./modules/howdy.nix
  ];

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
