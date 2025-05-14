{ config, lib, pkgs, modulesPath, ... }:

{
  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_cachyos; 

  boot.kernelParams = [ 
    # those actually do something
    "usbcore.autosuspend=-1" # keeps usb-c dock alive
    "btusb.enable_autosuspend=0" # keeps bluetooth alive
    "amdgpu.dcdebugmask=0x10" # refresh issues https://gitlab.gnome.org/GNOME/mutter/-/issues/3299\

    # Current NVME Case Controller
    # this garantees high speed mode
    # idVendor           0x152d JMicron Technology Corp. / JMicron USA Technology Corp.
    # idProduct          0x0583 JMS583Gen 2 to PCIe Gen3x2 Bridge
    "usb-storage.quirks=0x152d:0x0583:u"

    # debug
    "loglevel=7" # verbose
    "debug" # verbose
  ];

  # Configurar compressão
  boot.initrd.compressor = "lzop";

  # Userland Scheduler 
  # scx_rusty - responsive under load
  # scx_lavd - low latency
  services.scx.enable = true; 
  services.scx.scheduler = "scx_rusty"; 

  boot.kernelModules = [
    #hhhmmmm
    "nvme" 
    "usbhid" 
    "xhci_hcd" 
    "xhci_pci" 
    "typec" 
    "typec_ucsi" 
    "ext4"

    # for external nvme usb-c case
    "uas"
    "usbcore"
    "nvme"
    "nvme_core"
    "scsi_mod"
    "sd_mod"
  ];

  # # InitRD
  boot.initrd.availableKernelModules = [ 
    "nvme" 
    "usbhid" 
    "xhci_hcd" 
    "xhci_pci"
    "typec" 
    "typec_ucsi" 
    "ext4"

    # for external nvme usb-c case
    "uas"
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
  boot.kernel.sysctl = {
    "vm.swappiness" = 90;         # define a quantidade de memória swap a ser usada
  };
}
