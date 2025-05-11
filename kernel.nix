{ config, lib, pkgs, modulesPath, ... }:

{
  # Kernel
  # boot.kernelPackages = pkgs.linuxPackages_latest; 
  boot.kernelPackages = pkgs.linuxPackages_cachyos; 
  boot.kernelModules = [ "nvidia" "amdgpu" ];
  boot.kernelParams = [ 
    "amd_pstate=active" 
    "usbcore.autosuspend=-1" # keeps usb-c dock alive
    "nvidia-drm.modeset=1" 
  ];

  # Userland Scheduler 
  # Cachyos uses scx_rustland scheduler by default
  services.scx.enable = true; 
  services.scx.scheduler = "scx_rustland";

  # InitRD
  boot.initrd.kernelModules = [ "uhci_hcd" ];
  boot.initrd.availableKernelModules = [ 
    "nvme" 
    "xhci_pci" 
    "usbhid" 
    "usb_storage" 
    "uas" 
    "sd_mod" 
    "rtsx_pci_sdmmc" 
    "xhci_hcd" 
    "usb_storage" 
    "typec" 
    "typec_ucsi" 
    "usb_storage" 
    "ehci_pci" 
    "xhci_pci" 
    "ahci" 
    "sd_mod" 
    "ext4" 
  ];
}