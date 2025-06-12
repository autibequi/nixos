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
    device = "/dev/disk/by-uuid/6B74-DC9D";
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
    device = "/dev/disk/by-uuid/4265d4f9-7f7b-4ebf-a3b4-a3406c3c0955";
    fsType = "ext4"; # TODO: testar zfs com lz4 no proximo setup
    neededForBoot = true;
    options = [
      "defaults"
      "noatime"
      "discard"
    ];
  };

  # Hibernation
  boot.resumeDevice = "/dev/disk/by-uuid/4265d4f9-7f7b-4ebf-a3b4-a3406c3c0955";

  # Swap
  swapDevices = [
    { device = "/dev/disk/by-uuid/c824afe8-bf19-4f7f-9876-5fcff8c93593"; } # nomad usb stick
  ];
}
