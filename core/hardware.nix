{
  config,
  ...
}:
{
  config = {
    # Hibenration and swap are optional and can be commented out
    # Enable and configure the rest of the sistem in the modules
    fileSystems."/boot" = {
      device = config.diskUUIDs.boot;
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };

    fileSystems."/" = {
      device = config.diskUUIDs.root;
      fsType = "ext4"; # TODO: testar zfs com lz4 no proximo setup
      neededForBoot = true;
      options = [
        "defaults"
        "noatime"
        "discard"
      ];
    };

    # Hibernation
    boot.resumeDevice = config.diskUUIDs.swap;

    # Swap
    swapDevices = [ { device = config.diskUUIDs.swap; } ];
  };

}
