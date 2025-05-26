{ config, lib, pkgs, modulesPath, ... }:
{
  # Use this to override the hardware-configuration.nix file
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # are we ARM yet?
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # curent setup g14
  programs.rog-control-center.enable = true;
  services.supergfxd.enable = true;
  services = {
      asusd = {
        enable = true;
        enableUserService = true;
      };
  };

  # Hardware
  hardware = {
    enableAllFirmware = true;
    amdgpu.initrd.enable = true; # Fix low resolution on boot

    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        libvdpau-va-gl # Ponte VDPAU para VA-API (útil para compatibilidade)
      ];
    };
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };

  # Bootloader
  boot.kernelModules = [ "nvidia" "amdgpu"  ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 100;
  boot.loader.efi.canTouchEfiVariables = true;


  # X11 and Wayland
  services.xserver.videoDrivers = [ "nvidia" "amdgpu" ];

  # TODO: Try Next Reset
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

  # Root
  fileSystems."/" = {
      device = "/dev/disk/by-uuid/4265d4f9-7f7b-4ebf-a3b4-a3406c3c0955";
      fsType = "ext4"; # TODO: testar zfs com lz4 no proximo setup
      neededForBoot = true;
      options = [ "noatime" "nodiratime" "discard" "data=writeback" "barrier=0" ];
    };

  # Boot
  fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/6B74-DC9D";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  # Swap
  # Will try to mount on Stage 1
  swapDevices =
    [
      # TODO: fix, kinda worksbut takes a lot of time to boot until it times out
      # { device = "/dev/disk/by-uuid/0319478f-63cc-4fde-9804-523687d223ee"; priority = 10; options = [ "x-systemd.device-timeout=1ms" "nofail" ]; } # optional g14 laptop swap
      { device = "/dev/disk/by-uuid/c824afe8-bf19-4f7f-9876-5fcff8c93593"; } # nomad usb stick
    ];

  # Hibernate Configuration
  boot.resumeDevice = "/dev/disk/by-uuid/c824afe8-bf19-4f7f-9876-5fcff8c93593"; # Use the same as one of the swapDevices

  services.logind = {
    lidSwitch = "suspend-then-hibernate";
    powerKey = "hibernate";
    powerKeyLongPress = "poweroff";
  };

  # Define time delay for hibernation
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
    SuspendState=mem
  '';

  # Define kernel parameters for hibernation
  boot.kernelParams = ["mem_sleep_default=deep"];
}
