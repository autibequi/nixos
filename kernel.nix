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
    "fastboot" # acelera o processo de boot
    "noatime" # desativa atualização de timestamps de acesso
    "rd.systemd.show_status=false" # desativa mensagens de status do systemd durante boot
    "rd.udev.log_level=3" # reduz logs do udev
    "systemd.unified_cgroup_hierarchy=1" # usa cgroups v2 para melhor desempenho
    "preempt=full" # habilita preempção completa para melhor responsividade
    "threadirqs" # usa threads para IRQs melhorando responsividade
  ];

  # Otimizações de kernel
  boot.kernel.sysctl = {
    "vm.swappiness" = 1; # reduz drasticamente uso de swap para melhor responsividade
    "vm.vfs_cache_pressure" = 50; # melhora cache de sistema de arquivos
    "kernel.nmi_watchdog" = 0; # desativa NMI watchdog para economia de energia
    "net.core.netdev_max_backlog" = 16384; # aumenta backlog de rede
    "net.ipv4.tcp_fastopen" = 3; # habilita TCP Fast Open
    "vm.dirty_writeback_centisecs" = 1500; # reduz frequência de escrita em disco
    "vm.dirty_ratio" = 80; # aumenta buffer de escrita em disco
    "vm.dirty_background_ratio" = 5; # inicia escrita em background mais cedo
    "kernel.sched_autogroup_enabled" = 1; # melhora agrupamento de processos
    "kernel.sched_latency_ns" = 4000000; # reduz latência do escalonador
    "kernel.sched_min_granularity_ns" = 500000; # ajusta granularidade mínima
    "kernel.sched_wakeup_granularity_ns" = 50000; # melhora responsividade em wakeups
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
    memoryPercent = 75; # aumentado para reduzir paginação em disco
    priority = 100; # prioridade máxima para zram
  };

  # Otimização de I/O
  services.fstrim.enable = true; # trim periódico para SSDs
  programs.iotop.enable = true; # monitoramento de I/O
  
  # Configuração de I/O Scheduler para melhor responsividade
  services.udev.extraRules = ''
    # Usar scheduler BFQ para discos mecânicos e none para SSDs
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
  '';
  
  # Acelerar boot desabilitando serviços não essenciais
  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.services.systemd-udev-settle.enable = false;
}