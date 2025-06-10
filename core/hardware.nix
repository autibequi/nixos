{
  lib,
  modulesPath,
  ...
}:
{
  # Use this to override the hardware-configuration.nix file
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # are we ARM yet?
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Hardware
  # Stallman would be very sad with me...
  hardware = {
    enableAllFirmware = true;
    enableAllHardware = true;
    enableRedistributableFirmware = true;
    amdgpu.initrd.enable = true;
    cpu.amd.updateMicrocode = true;
  };

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Graphical Driver List
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Boot
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6B74-DC9D";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # Root
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
  # Check modules/battery.nix for more hibernation config
  boot.resumeDevice = "/dev/disk/by-uuid/4265d4f9-7f7b-4ebf-a3b4-a3406c3c0955";

  # Swap - Will try to mount on Stage 1
  swapDevices = [
    { device = "/dev/disk/by-uuid/c824afe8-bf19-4f7f-9876-5fcff8c93593"; } # nomad usb stick
  ];

  # TODO: FULL DISK ENCRYPTION
  # LUKS FullDiskEncryption
  # boot.initrd.luks.devices = {
  #   luksroot = {
  #       device = "/dev/disk/by-uuid/4265d4f9-7f7b-4ebf-a3b4-a3406c3c0955";
  #       allowDiscards = true;
  #       keyFileSize = 4096;
  #       # pinning to /dev/disk/by-id/usbkey works
  #       keyFile = "/dev/sdb";
  #   };
  # };
}
