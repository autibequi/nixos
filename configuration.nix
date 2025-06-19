{
  ...
}:

# Instalation
# Just setup the root, boot and swap partitions
# If you dont want swap or hibernation, just comment out the swapDevices and boot.resumeDevice
let
  swapDiskUUID = "/dev/disk/by-uuid/c824afe8-bf19-4f7f-9876-5fcff8c93593";
  bootDiskUUID = "/dev/disk/by-uuid/6B74-DC9D";
  rootDiskUUID = "/dev/disk/by-uuid/4265d4f9-7f7b-4ebf-a3b4-a3406c3c0955";
in
{
  # System State Version
  system.stateVersion = "25.05";

  imports = [
    # Core
    ./core/nix.nix
    ./core/core.nix
    ./core/kernel.nix
    ./core/home.nix
    ./core/services.nix
    ./core/programs.nix
    ./core/packages.nix
    ./core/shell.nix
    ./core/fonts.nix

    # Extra
    ./modules/ai.nix
    ./modules/asus.nix
    ./modules/battery.nix
    ./modules/bluetooth.nix
    # ./modules/podman.nix
    ./modules/nvidia.nix
    ./modules/plymouth.nix
    # ./modules/howdy.nix
    # ./modules/flatpak.nix
    ./modules/work.nix

    # Desktop Environments
    ./modules/gnome/core.nix
    ./modules/cosmic.nix
    # ./modules/kde.nix
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
