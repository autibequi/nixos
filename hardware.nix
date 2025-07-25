# Instalation
# Create a copy of this file name hardware.nix with such inside:
# In a fresh start this info can be retrieve by:
#
# cat /etc/nixos/hardware-configuration.nix | grep -B 3 "device ="
#
{ lib, ... }:
{
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
