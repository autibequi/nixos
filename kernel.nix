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
    "nohz_full" # reduz interrupções do timer
    "rcu_nocbs" # reduz overhead do RCU
    "processor.max_cstate=1" # limita estados de energia do processador
    "intel_idle.max_cstate=1" # limita estados de energia do processador Intel
    "idle=poll" # reduz latência de wakeup
    "nowatchdog" # desativa watchdog timer
    "nmi_watchdog=0" # desativa NMI watchdog
    "quiet" # reduz mensagens de boot
    "loglevel=3" # reduz nível de log

    # Melhora Boot time
    "fastboot" # acelera o processo de boot
  ];

  # Configurar compressão
  boot.initrd.compressor = "lzop";

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
