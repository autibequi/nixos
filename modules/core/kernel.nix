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
    "usbcore.autosuspend=-1"
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

  # Userland Scheduler
  services.scx.enable = true;
  powerManagement.cpuFreqGovernor = "schedutil"; # needed for scx (ideal for power saving)
  services.scx.scheduler = "scx_rusty"; # scx_rusty é mais lento, mas é mais preciso e estável

  # AMD Power Management Indication
  services.auto-epp.enable = true;

  # Otimizações de I/O
  services.fstrim.enable = true;
  services.fstrim.interval = "weekly";
}
