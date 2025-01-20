# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{

  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # Plataform
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  nixpkgs.config.cudaSupport = true;

  # Basics
  hardware.pulseaudio.enable = false;
  hardware.graphics.enable = true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # InitRD
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" "usb_storage" "uas" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];

  # Kernel
  # Optional: Enable CachyOS binary cache
  boot.kernelPackages = pkgs.linuxPackages_cachyos; 
  boot.kernelModules = [ "nvidia" "kvm-amd" "amdgpu" ];
  boot.kernelParams = [ ];

  # Video
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

  # Filesystems
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/4265d4f9-7f7b-4ebf-a3b4-a3406c3c0955";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/6B74-DC9D";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/c824afe8-bf19-4f7f-9876-5fcff8c93593"; }
    ];

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    modesetting.enable = true; # Modesetting is required.
    nvidiaSettings = false;
    
    # Power Management
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    
    # RTX 4060 G402
    open = true;
    prime = {
      offload.enable = true;
      reverseSync.enable = true;
      
      amdgpuBusId = lib.mkDefault "PCI:65:0:0";
      nvidiaBusId = lib.mkDefault "PCI:1:0:0";
    };
  };
}


