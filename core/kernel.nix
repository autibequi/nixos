{ config, lib, pkgs, modulesPath, ... }:

{
  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_cachyos; 

  boot.kernelParams = [ 
    # those actually do something
    "fastboot" # faster boot
    # "usbcore.autosuspend=-1" # keeps usb-c dock alive
    "amdgpu.dcdebugmask=0x10" # refresh issues https://gitlab.gnome.org/GNOME/mutter/-/issues/3299\

    # Force UAS for external NVME USB-C case; this garantees high speed mode | lsusb -t:
    # idVendor           0x152d JMicron Technology Corp. / JMicron USA Technology Corp.
    # idProduct          0x0583 JMS583Gen 2 to PCIe Gen3x2 Bridge
    "usb-storage.quirks=0x152d:0x0583:i"
  ];

  # Configurar compressão.
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/kernel/initrd-compressor-meta.nix
  boot.initrd.compressor = "lzop"; # TODO: lz4 should be faster
  boot.initrd.compressorArgs = [ "--best" ];
  
  # Userland Scheduler 
  # scx_rusty - responsive under load
  # scx_lavd - better battery life???
  services.scx.enable = true; 
  services.scx.scheduler = "scx_lavd"; 

  # TODO: clean up modules
  boot.kernelModules = [
    # maybe
    "usbhid" 
    "xhci_hcd" 
    "xhci_pci" 
    "typec" 
    "typec_ucsi" 
    "ext4"
    "acpi_call"

    # for external nvme usb-c case
    "uas"
    "usb_storage"
    "usbcore"
    "nvme"
    "nvme_core"
    "scsi_mod"
    "sd_mod"
  ];

  # TODO: clean up initrd modules
  # InitRD
  boot.initrd.availableKernelModules = [ 
    # maybe?
    "usbhid" 
    "xhci_hcd" 
    "xhci_pci"
    "typec" 
    "typec_ucsi" 
    "ext4"

    # for external nvme usb-c case
    "uas"
    "usb_storage"
    "usbcore"
    "nvme"
    "nvme_core"
    "scsi_mod"
    "sd_mod"
  ];

  # Acelerar boot desabilitando serviços não essenciais
  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.services.systemd-udev-settle.enable = false;

  # Otimizações de I/O
  services.fstrim.enable = true;
  services.fstrim.interval = "weekly";
  
  # Otimizações de Memória
  # Como nos dois setupts temos 48gb e 64gb de ram usamos o
  # minimo possivel pra poupar uso do disco
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
  };
}
