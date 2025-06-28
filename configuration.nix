{
  ...
}:

# Instalation
# Just setup the root, boot and swap partitions
# If you dont want swap or hibernation, just comment out the swapDevices and boot.resumeDevice
#
# This file is locked by .gitinore wont be commitable to avoid conflits.
# Use setup.nix to enable ore disable packages
let
  bootDiskUUID = "/dev/disk/by-uuid/1F53-9115";
  rootDiskUUID = "/dev/disk/by-uuid/ee52cc58-f10d-4979-8244-4386302649c5";
  swapDiskUUID = "/dev/disk/by-uuid/17e5c565-c90c-4233-92c6-bb86adfed306";
in
{
  system.stateVersion = "25.11";

  # Importa Setup do Usuario
  imports = [
    # Core
    ./core/nix.nix
    ./core/core.nix
    ./core/home.nix
    ./core/services.nix
    ./core/programs.nix
    ./core/packages.nix
    ./core/shell.nix
    # ./core/fonts.nix
    # ./modules/plymouth.nix
    # ./core/kernel.nix
    # ./modules/nvidia.nix

    # Desktop Environments
    ./modules/gnome/core.nix
    # ./modules/cosmic.nix
    # ./modules/kde.nixs

    # Extra
    # ./modules/ai.nix
    # ./modules/asus.nix
    # ./modules/battery.nix
    # ./modules/bluetooth.nix
    # ./modules/podman.nix
    # ./modules/howdy.nix
    # ./modules/flatpak.nix
    # ./modules/work.nix
  ];

  # --------------------------------
  # The rest is puremapping boilerplate
  # --------------------------------

  # Hibenration and swap are optional and can be commented out
  # Enable and configure the rest of the sistem in the modules
  fileSystems."/boot" = {
    device = bootDiskUUID;
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  fileSystems."/" = {
    device = rootDiskUUID;
    fsType = "ext4"; # TODO: testar zfs com lz4 no proximo setup
    neededForBoot = true;
    options = [
      "defaults"
      "noatime"
      "discard"
    ];
  };

  # Hibernation
  boot.resumeDevice = swapDiskUUID;

  # Swap
  swapDevices = [ { device = swapDiskUUID; } ];
}
