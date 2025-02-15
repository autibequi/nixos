{ config, lib, pkgs, modulesPath, ... }:

{
  # Kernel
  # boot.kernelPackages = pkgs.linuxPackages_latest; 
  boot.kernelPackages = pkgs.linuxPackages_cachyos; 
  boot.kernelModules = [ "nvidia" "amdgpu" ];
  boot.kernelParams = [ 
    "processor.max_cstate=5"  # Prevents deep sleep states from causing hangs
    "amd_pstate=active" 
    "usbcore.autosuspend=-1" 
    "nvidia-drm.modeset=1" 
  ];
  boot.extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];

  # Userland Scheduler 
  # Cachyos uses scx_rustland scheduler by default
  services.scx.enable = true; 
  services.scx.scheduler = "scx_lavd";

  # InitRD
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" "usb_storage" "uas" "sd_mod" "rtsx_pci_sdmmc" "xhci_hcd" "usb_storage" "typec" "typec_ucsi" ];
  boot.initrd.kernelModules = [ ];
}