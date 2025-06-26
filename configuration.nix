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
  swapDiskUUID = "/dev/disk/by-uuid/c824afe8-bf19-4f7f-9876-5fcff8c93593";
  bootDiskUUID = "/dev/disk/by-uuid/6B74-DC9D";
  rootDiskUUID = "/dev/disk/by-uuid/4265d4f9-7f7b-4ebf-a3b4-a3406c3c0955";
in
{
  # Importa Setup do Usuario
  imports = [
    ./setup.nix
  ];

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
