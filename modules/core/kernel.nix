{
  pkgs,
  lib,
  ...
}:
{
  # Zen Kernel (fallback 'cos cachyos too edgy)
  # boot.kernelPackages = pkgs.linuxPackages_zen;

  # CachyOS Kernel (With weird workaround)
  # https://github.com/chaotic-cx/nyx/issues/1158
  system.modulesTree = [ (lib.getOutput "modules" pkgs.linuxPackages_cachyos.kernel) ];
  boot.kernelPackages = pkgs.linuxPackages_cachyos;

  # SystemD no InitRD para hibernação moderna
  boot.initrd.systemd.enable = true;

  # Permitir hibernação (desabilita proteção de kernel image)
  security.protectKernelImage = false;

  boot.kernelParams = [
    "usbcore.autosuspend=1" # Habilita o auto-suspend de USBs para economizar energia (estava desabilitado)
    # refresh issues https://gitlab.gnome.org/GNOME/mutter/-/issues/3299\ (Mutter bug, not relevant for Hyprland)
    # "amdgpu.dcdebugmask=0x10"

    # Force UAS for external NVME USB-C case; this garantees high speed mode | lsusb -t:
    # idVendor           0x152d JMicron Technology Corp. / JMicron USA Technology Corp.
    # idProduct          0x0583 JMS583Gen 2 to PCIe Gen3x2 Bridge
    # i - usb-storage disasbled
    # u - enable (faster)(this flat is a headache but works i guess)
    "usb-storage.quirks=0x152d:0x0583:u"

    # Força o uso do p-state ativo para o processador AMD
    # active so epp modes will work
    "amd_pstate=guided" # best
    # "amd_pstate=active" # defautl
    "bgrt_disable"
    "mitigations=off"
    "iommu=pt"
    # "preempt=full" # Preemptive scheduling for better responsiveness
    "libahci.ignore_sss=1" # Disable AHCI SSS (Serial ATA Status and Status Change)
    "scsi_mod.use_blk_mq=1" # Habilita o Multi-Queue Block Layer (necessário para os novos schedulers)
    "pcie_aspm=force" # Força o gerenciamento de energia do PCIe para economia máxima
  ];

  # Otimiza o uso da RAM e I/O para economia de energia
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
  };

  # Otimiza o uso do disco para melhor performance
  fileSystems."/".options = [ "defaults" "noatime" ];

  # Configurar compressão.
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/kernel/initrd-compressor-meta.nix
  boot.initrd.compressor = "zstd"; # zstd is faster for decompression
  boot.initrd.compressorArgs = [ "-19" ]; # Max compression for zstd

  # Userland Scheduler (Otimizado para Bateria)
  services.scx.enable = true;
  powerManagement.cpuFreqGovernor = "schedutil"; # needed for scx (ideal for power saving)
  services.scx.scheduler = "scx_lavd"; # Low-latency Application-aware Virtual Deadline
  services.scx.extraArgs = [ 
    "--autopower"
  ];

  # Módulos do Kernel (Otimizados e Limpos)
  boot.kernelModules = [
    # ═══ Virtualização ═══
    "kvm-amd" 
    
    # ═══ AMD Power Management ═══
    "amd_pstate" # Driver de p-state moderno (necessário para amd_pstate=guided)
    "amd_energy" # Monitoramento de energia AMD
    "amd_pmf" # Platform Management Framework (laptop power features)
    
    # ═══ ACPI & Power Management ═══
    "acpi_call" # Chamadas ACPI customizadas (power management avançado)
    
    # ═══ USB & Type-C ═══
    "usbhid"
    "xhci_hcd"
    "xhci_pci"
    "typec"
    "typec_ucsi"
    "ucsi_acpi"

    # ═══ Storage (External NVMe USB-C) ═══
    "uas" # USB Attached SCSI
    "usb_storage"
    "usbcore"
    "nvme"
    "nvme_core"
    "scsi_mod"
    "sd_mod"
    "ext4"
  ];

  # InitRD - Módulos essenciais para boot e resume (NVMe externo via USB-C)
  boot.initrd.availableKernelModules = [
    # ═══ USB Controllers ═══
    "usbhid"
    "xhci_hcd"
    "xhci_pci"
    
    # ═══ USB Type-C ═══
    "typec"
    "typec_ucsi"

    # ═══ Storage Drivers ═══
    "uas" # USB Attached SCSI (crítico para NVMe USB-C)
    "usb_storage"
    "usbcore"
    "nvme"
    "nvme_core"
    "scsi_mod"
    "sd_mod"
    
    # ═══ Filesystem ═══
    "ext4"
  ];

  # Otimizações de I/O
  services.fstrim.enable = true;
  services.fstrim.interval = "weekly";
}
