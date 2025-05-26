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

  # Resume Device - apontando para o swap ativo em /dev/sda3
  boot.resumeDevice = "/dev/sda3";

  # Boot
  fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/6B74-DC9D";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  # Swap - usando o dispositivo principal que já está ativo
  swapDevices = [
    { device = "/dev/sda3"; }
  ];

    # TODO: systemd mount
    # systemd.services.optionalSwap = {
    #   description = "Enable optional swap if device is present";
    #   wantedBy = [ "multi-user.target" ];
    #   script = ''
    #     if [ -e /dev/disk/by-uuid/c824afe8-bf19-4f7f-9876-5fcff8c93593 ]; then
    #       swapon /dev/disk/by-uuid/c824afe8-bf19-4f7f-9876-5fcff8c93593
    #     fi
    #   '';
    #   serviceConfig.Type = "oneshot";
    # };
}


