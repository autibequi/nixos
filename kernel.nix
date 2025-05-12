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
    "mitigations=off" # melhora desempenho desativando mitigações de segurança
    "nowatchdog" # desativa o watchdog para melhorar desempenho
    "quiet" # reduz mensagens de boot
    "loglevel=3" # limita logs do kernel
  ];

  # Otimizações de kernel
  boot.kernel.sysctl = {
    "vm.swappiness" = 10; # reduz uso de swap
    "vm.vfs_cache_pressure" = 50; # melhora cache de sistema de arquivos
    "kernel.nmi_watchdog" = 0; # desativa NMI watchdog para economia de energia
    "net.core.netdev_max_backlog" = 16384; # aumenta backlog de rede
    "net.ipv4.tcp_fastopen" = 3; # habilita TCP Fast Open
  };

  # Userland Scheduler 
  services.scx.enable = true; 
  services.scx.scheduler = "scx_simple";

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

  # Habilitar suporte a compressão zram para melhor desempenho
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # Otimização de I/O
  services.fstrim.enable = true; # trim periódico para SSDs
}