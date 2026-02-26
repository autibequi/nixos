{
  pkgs,
  lib,
  ...
}:
{
  # Default Kernel (from NixOS)
  # boot.kernelPackages = pkgs.linuxPackages_latest;

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
    "fastboot"
    "quiet"
    "bgrt_disable"
    "amd_pstate=active" # active/guided/passive - active é muito mais rápido e responsivo

    # USB: autosuspend 2s economiza bateria (se algum device der problema, volte -1)
    # "usbcore.autosuspend=-1"

    # Crazy Experimental
    "iommu=pt"
    "nvidia.NVreg_DynamicPowerManagement=0x02"
    "nvidia-drm.fbdev=1"
    "nvidia-drm.modeset=1"
  ];

  boot.kernel.sysctl = {
    # NVMe interno é rápido o suficiente para se beneficiar de swappiness moderado.
    # 10-20 significa que o kernel só começa a usar swap quando a RAM fica escassa,
    # mas ainda permite que páginas frias sejam movidas proativamente.
    "vm.swappiness" = 10;

    # Pressão de cache padrão: 100 seria agressivo demais para um SSD rápido.
    # 50 mantém um bom equilíbrio entre reutilizar cache e liberar memória.
    "vm.vfs_cache_pressure" = 50;

    # NVMe interno aguenta rajadas de escrita muito bem.
    # Limites mais generosos reduzem stalls de CPU por flush prematuro.
    "vm.dirty_ratio" = 20;           # flush forçado ao atingir 20% da RAM
    "vm.dirty_background_ratio" = 10; # flush em background começa aos 10%
  };

  # Otimiza o uso do disco para melhor performance
  fileSystems."/".options = [ "defaults" "noatime" ];

  # Configurar compressão.
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/kernel/initrd-compressor-meta.nix
  # zstd -3: descompressão rápida em NVMe interno (~2x mais rápido que -19),
  # o delta de tamanho é insignificante quando a leitura não é o gargalo.
  boot.initrd.compressor = "zstd";
  boot.initrd.compressorArgs = [ "-3" ];

  # Userland Scheduler
  services.scx.enable = true;
  powerManagement.cpuFreqGovernor = "schedutil"; # needed for scx (ideal for power saving)
  services.scx.scheduler = "scx_bpfland"; # scx_rusty é mais lento, mas é mais preciso e estável

  # AMD Power Management Indication
  services.auto-epp.enable = true;

  # TRIM periódico para saúde do NVMe interno
  services.fstrim.enable = true;
  services.fstrim.interval = "weekly";
}
