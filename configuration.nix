{
  ...
}:

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
    ./modules/asus.nix
    ./modules/battery.nix
    ./modules/bluetooth.nix
    ./modules/nvidia.nix
    ./modules/plymouth.nix
    # ./modules/howdy.nix
    # ./modules/flatpak.nix
    # ./modules/ai.nix

    # Work
    ./modules/work.nix

    # Desktop Environments
    ./desktop-envs/gnome/core.nix
    ./desktop-envs/cosmic.nix
    # ./desktop-envs/kde.nix
  ];

  # Instalatio
  # Just setup the root, boot and swap partitions
  # Hibenration and swap are optional and can be commented out
  # Enable and configure the rest of the sistem in the modules
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6B74-DC9D";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

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
    { device = "/dev/disk/by-uuid/c824afe8-bf19-4f7f-9876-5fcff8c93593"; }
  ];
}
