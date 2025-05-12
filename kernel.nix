{ config, lib, pkgs, modulesPath, ... }:

{
  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_cachyos; 
  boot.kernelModules = [ "nvidia" "amdgpu" ];
  boot.kernelParams = [ 
    # those actually do something
    "usbcore.autosuspend=-1" # keeps usb-c dock alive
    "btusb.enable_autosuspend=0" # keeps bluetooth alive
    "amdgpu.dcdebugmask=0x10" # refresh issues https://gitlab.gnome.org/GNOME/mutter/-/issues/3299

    # Otimizações de Performance
    "mitigations=off" # melhora desempenho desativando mitigações de segurança
    "preempt=full" # habilita preempção completa para melhor responsividade
    "threadirqs" # usa threads para IRQs melhorando responsividade

    # Melhora Boot time
    "loglevel=3" # limita logs do kernel
    "fastboot" # acelera o processo de boot
    "quiet" # reduz mensagens de boot
    "splash" # habilita splash screen
  ];


  # Configurar compressão
  # boot.initrd.compressor = "lz4";

  # Userland Scheduler 
  # scx_rusty - responsive under load
  # scx_lavd - low latency
  services.scx.enable = true; 
  services.scx.scheduler = "scx_rusty"; 

  # # InitRD
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

  # Configure initramfs modules
  boot.loader.systemd-boot.editor = false; # Disable boot editor
  boot.loader.timeout = 0; # Reduce timeout

  # Otimização de I/O
  services.fstrim.enable = true; # trim periódico para SSDs
  programs.iotop.enable = true; # monitoramento de I/O
  
  # Acelerar boot desabilitando serviços não essenciais
  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.services.systemd-udev-settle.enable = false;
}
