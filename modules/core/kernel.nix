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

  # Menos logs até o greeter (Plymouth removido — boot rápido)
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;

  # Permitir hibernação (desabilita proteção de kernel image)
  security.protectKernelImage = false;

  boot.kernelParams = [
    # Console: só framebuffer; evita esperar serial (ttyS0–ttyS3) no boot.
    "console=tty0"

    # Logs
    "fastboot"
    "quiet"
    "loglevel=0"
    "bgrt_disable"

    "udev.log_priority=3"
    "rd.udev.log_priority=3"
    "rd.systemd.show_status=false"
    "systemd.log_level=err"
    "vt.global_cursor_default=0"

    # Watchdog disable (sysctl + cmdline para garantir)
    "nowatchdog"
    "nmi_watchdog=0"

    # Disable USB autosuspend to avoid issues with USB devices.
    "usbcore.autosuspend=2"

    # Disable mitigations for speed
    "mitigations=off"

    # Hugepages: madvise balanceia retenção de memória com perf de apps que usam madvise.
    "transparent_hugepage=madvise"

    # Nvidia
    "nvidia.NVreg_DynamicPowerManagement=0x02"
    "nvidia-drm.fbdev=1"
    "nvidia-drm.modeset=1"

    # AMD
    "amd_pstate=active" # active/guided/passive - active é muito mais rápido e responsivo
  ];

  boot.blacklistedKernelModules = [
    # Disable TPM
    "tpm"
    "tpm_tis"
    "tpm_crb"
    # Disable serial ports (3.5s boot penalty waiting for ttyS0-S3)
    "8250_pci"
    "serial_8250"
  ];

  # Disable TPM
  boot.initrd.systemd.tpm2.enable = false;
  systemd.tpm2.enable = false;

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
    "vm.dirty_ratio" = 20; # flush forçado ao atingir 20% da RAM
    "vm.dirty_background_ratio" = 10; # flush em background começa aos 10%

    # Flush proativo: reduz wakeups e permite que a drive batch writes melhor.
    "vm.dirty_expire_centisecs" = 3000; # 30s (padrão, explícito)
    "vm.dirty_writeback_centisecs" = 1500; # flush a cada 15s ao invés de 5s

    # sched_autogroup: agrupa processos do mesmo terminal/sessão e aplica
    # nice diferenciado por grupo — impede que builds pesados (cargo, gradle,
    # flutter) engulam o timeslice das janelas interativas.
    "kernel.sched_autogroup_enabled" = 1;

    # Scheduler granularity: reduz microstutter em cargas pesadas.
    # 1ms wakeup granularity para tarefa interactive, 500µs para aplicações despertando.
    "kernel.sched_min_granularity_ns" = 1000000;
    "kernel.sched_wakeup_granularity_ns" = 500000;

    # Desabilita NMI watchdog via sysctl (complementa nmi_watchdog=0 no cmdline).
    "kernel.nmi_watchdog" = 0;

    # Compactação de memória proativa em background: reduz stalls de alocação
    # de hugepages ao manter memória contígua disponível antecipadamente.
    # 20 é conservador o suficiente para não interferir com uso interativo.
    "vm.compaction_proactiveness" = 20;

    # Rede: buffers maiores para melhor throughput
    "net.core.netdev_max_backlog" = 16384;
    "net.ipv4.tcp_fastopen" = 3;

    # Inotify: suficiente para IDEs e file watchers (padrão é 8192)
    "fs.inotify.max_user_watches" = 524288;
  };

  # Configurar compressão.
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/kernel/initrd-compressor-meta.nix
  # zstd -3: descompressão rápida em NVMe interno (~2x mais rápido que -19),
  # o delta de tamanho é insignificante quando a leitura não é o gargalo.
  boot.initrd.compressor = "zstd";
  boot.initrd.compressorArgs = [ "-3" ];

  # Userland Scheduler
  services.scx.enable = true;
  # scx_lavd (Latency-Aware Virtual Deadline) é mais responsivo para uso
  # interativo/desktop do que bpfland, especialmente em CPUs AMD híbridas.
  # bpfland é ótimo para throughput misto, mas lavd prioriza latência de UI.
  # --autopilot: lavd detecta AC/BAT automaticamente e ajusta seu comportamento
  # interno (boosting, core compaction) sem precisar de configuração manual.
  services.scx.scheduler = "scx_lavd";
  services.scx.extraArgs = [ "--autopilot" ];

  # AMD Power Management Indication
  # auto-epp ajusta o EPP do amd_pstate automaticamente conforme AC/BAT:
  #   - AC  → energy_performance_preference = "performance"
  #   - BAT → energy_performance_preference = "power" ou "balance_power"
  # Isso substitui o papel do power-profiles-daemon de forma mais leve e
  # sem conflitar com o schedutil + SCX.
  services.auto-epp.enable = true;

  # earlyoom: mata processos quando RAM < 5% para evitar travamento total
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;
    freeSwapThreshold = 10;
    enableNotifications = true;
  };

  # TRIM periódico para saúde do NVMe interno
  services.fstrim.enable = true;
  services.fstrim.interval = "weekly";

  # NVMe já faz scheduling interno; mq-deadline adiciona latência sem ganho.
  # Forçar "none" iguala ao comportamento típico no Windows e melhora throughput.
  services.udev.extraRules = ''
    SUBSYSTEM=="block", ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
  '';
}
