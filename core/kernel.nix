{
  pkgs,
  ...
}:

{
  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_cachyos; # change to latest after nvidia wakeup and work

  # SystemD no InitRD para hibernação moderna
  boot.initrd.systemd.enable = true;

  # Permitir hibernação (desabilita proteção de kernel image)
  security.protectKernelImage = false;

  boot.kernelParams = [
    "fastboot"
    "amdgpu.dcdebugmask=0x10" # refresh issues https://gitlab.gnome.org/GNOME/mutter/-/issues/3299\

    "amdgpu.aspm=1" # Enable ASPM for AMD GPUs
    "amdgpu.ppfeaturemask=0xffffffff" # Enable all power management features for AMD GPUs
    "amdgpu.dpm=1" # Enable Dynamic Power Management for AMD GPUs

    # Force UAS for external NVME USB-C case; this garantees high speed mode | lsusb -t:
    # idVendor           0x152d JMicron Technology Corp. / JMicron USA Technology Corp.
    # idProduct          0x0583 JMS583Gen 2 to PCIe Gen3x2 Bridge
    # i - usb-storage disasbled
    # u - enable (slow mode)
    "usb-storage.quirks=0x152d:0x0583:i"

    # Força o uso do p-state ativo para o processador AMD
    "amd_pstate=guided"
  ];

  # Configurar compressão.
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/kernel/initrd-compressor-meta.nix
  boot.initrd.compressor = "lzop"; # Voltando para lzop (mais estável)
  boot.initrd.compressorArgs = [ "-9" ]; # Args para lzop (high compression)

  # Userland Scheduler
  services.scx.enable = true;
  services.scx.package = pkgs.scx_git.full; # latest updates
  powerManagement.cpuFreqGovernor = "schedutil"; # needed for scx
  services.scx.scheduler = "scx_lavd";
  services.scx.extraArgs = [ "--autopower" ];

  # TODO: clean up moduless
  boot.kernelModules = [
    # maybe
    "usbhid"
    "xhci_hcd"
    "xhci_pci"
    "typec"
    "typec_ucsi"
    "ext4"
    "acpi_call" # Mantido, pode ser útil para power management específico de hardware

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
  # InitRD - Módulos essenciais para boot e resume, especialmente com root em NVMe externo
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

  # Otimizações de I/O
  services.fstrim.enable = true;
  services.fstrim.interval = "weekly";

  # Otimizações de Memória
  # Como nos dois setupts temos 48gb e 64gb de ram usamos o
  # minimo possivel pra poupar uso do disco
  boot.kernel.sysctl = {
    "vm.swappiness" = 10; # Mantido, baixo swappiness é ok
  };
}
