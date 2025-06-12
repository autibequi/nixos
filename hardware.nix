{
  ...
}:
{
  #  ____              _
  # | __ )  ___   ___ | |_
  # |  _ \ / _ \ / _ \| __|
  # | |_) | (_) | (_) | |_
  # |____/ \___/ \___/ \__|
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/<CHANGE THIS>";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  #  ____            _
  # |  _ \ ___  _ __| |_
  # | |_) / _ \| '__| __|
  # |  _ < (_) | |  | |_
  # |_| \_\___/|_|   \__|
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/<CHANGE THIS>";
    fsType = "ext4"; # TODO: testar zfs com lz4 no proximo setup
    neededForBoot = true;
    options = [
      "defaults"
      "noatime"
      "discard"
    ];
  };

  # Hibernation
  boot.resumeDevice = "/dev/disk/by-uuid/<CHANGE THIS, same as ROOT>";

  # Swap
  swapDevices = [
    { device = "/dev/disk/by-uuid/<CHANGE THIS>"; } # nomad usb stick
  ];
}
