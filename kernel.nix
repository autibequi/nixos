{ config, lib, pkgs, modulesPath, ... }:

{
  # Kernel
  # boot.kernelPackages = pkgs.linuxPackages_latest; 
  boot.kernelPackages = pkgs.linuxPackages_cachyos; 
  boot.kernelModules = [ "nvidia" "amdgpu" ];
  boot.kernelParams = [ 
    "usbcore.autosuspend=-1" # keeps usb-c dock alive
    "btusb.enable_autosuspend=0" # keeps bluetooth alive
    "amdgpu.dcdebugmask=0x10" # refresh issues https://gitlab.gnome.org/GNOME/mutter/-/issues/3299
  ];

  # Userland Scheduler 
  services.scx.enable = true; 
  # services.scx.scheduler = "scx_simple";
  services.scx.scheduler = "scx_flash";

  # InitRD
  boot.initrd.availableKernelModules = [ 
    "nvme" 
    "usbhid" 
    "usb_storage" 
    "uas" 
    "xhci_hcd" 
    "typec" 
    "typec_ucsi" 
    "ext4" 
  ];
}