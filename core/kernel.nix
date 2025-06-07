{
  pkgs,
  ...
}:

{
  # Kernel
  # If broken plz change to linuxPackages_x_xx until nvidia update their drivers
  boot.kernelPackages = pkgs.linuxPackages_cachyos;

  # SystemD no InitRD para hibernação moderna
  boot.initrd.systemd.enable = true;

  # Permitir hibernação (desabilita proteção de kernel image)
  security.protectKernelImage = false;

  boot.kernelParams = [
    "amdgpu.dcdebugmask=0x10" # refresh issues https://gitlab.gnome.org/GNOME/mutter/-/issues/3299\
    # Force UAS for external NVME USB-C case; this garantees high speed mode | lsusb -t:
    # idVendor           0x152d JMicron Technology Corp. / JMicron USA Technology Corp.
    # idProduct          0x0583 JMS583Gen 2 to PCIe Gen3x2 Bridge
    # i - usb-storage disasbled
    # u - enable (slow mode)
    "usb-storage.quirks=0x152d:0x0583:i"

    # Força o uso do p-state ativo para o processador AMD
    # active so epp modes will work
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
    "ucsi_acpi"

    # Testing
    "amd_energy"
    "amd_pmf"
    "pcie_aspm=force"
    "bbswitch" # for dGPU power management

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
