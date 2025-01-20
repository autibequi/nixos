{ config, lib, pkgs, modulesPath, ... }:

{
  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_cachyos; 
  boot.kernelModules = [ "nvidia" "kvm-amd" "amdgpu" ];
  boot.kernelParams = [
    "sched_ext_ops_helper=off"
  ];

  #CACHYOS KERNEL: by default uses scx_rustland scheduler
  services.scx.enable = true; 

  # InitRD
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" "usb_storage" "uas" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
}