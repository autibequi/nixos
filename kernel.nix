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
    "nowatchdog" # desativa o watchdog para melhorar desempenho
    "systemd.unified_cgroup_hierarchy=1" # usa cgroups v2 para melhor desempenho
    "preempt=full" # habilita preempção completa para melhor responsividade
    "threadirqs" # usa threads para IRQs melhorando responsividade
    "iomem=relaxed" # melhora acesso à memória para aplicações de desenvolvimento
    "pcie_aspm=off" # desativa economia de energia PCIe para melhor desempenho
    "intel_iommu=on" # habilita IOMMU para melhor desempenho em virtualização
    "amd_iommu=on" # habilita IOMMU para melhor desempenho em virtualização
    "noapic" # desativa APIC para melhor desempenho
    "noirqbalance" # desativa balanceamento de IRQs para melhor desempenho

    # Melhora Boot time
    "rd.systemd.show_status=false" # desativa mensagens de status do systemd durante boot
    "rd.udev.log_level=3" # reduz logs do udev
    "noatime" # desativa atualização de timestamps de acesso
    "loglevel=3" # limita logs do kernel
    "fastboot" # acelera o processo de boot
    "quiet" # reduz mensagens de boot
    "splash" # habilita splash screen
  ];

  # Otimizações de kernel para desenvolvimento web
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
    "fs.inotify.max_user_watches" = 524288; # aumenta limite de watches para ferramentas de desenvolvimento
    "net.core.somaxconn" = 4096; # aumenta conexões simultâneas para servidores de desenvolvimento
    "net.ipv4.tcp_max_syn_backlog" = 8192; # melhora desempenho para múltiplas conexões HTTP
    "net.ipv4.ip_local_port_range" = "1024 65535"; # amplia range de portas para desenvolvimento
  };

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

  # Habilitar suporte a compressão zram para melhor desempenho
  # Not necessario because lots of ram
  # zramSwap = {
  #   enable = true;
  #   algorithm = "zstd";
  #   memoryPercent = 75; # aumentado para reduzir paginação em disco
  #   priority = 100; # prioridade máxima para zram
  # };

  # Otimização de I/O
  services.fstrim.enable = true; # trim periódico para SSDs
  programs.iotop.enable = true; # monitoramento de I/O
  
  # Configuração de I/O Scheduler para melhor responsividade
  services.udev.extraRules = ''
    # Aumentar limites para dispositivos de entrada para melhor experiência de desenvolvimento
    KERNEL=="event*", SUBSYSTEM=="input", RUN+="${pkgs.kmod}/bin/modprobe -a uinput"
  '';
  
  # Acelerar boot desabilitando serviços não essenciais
  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.services.systemd-udev-settle.enable = false;
}
