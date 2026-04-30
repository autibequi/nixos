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

    # Desabilita USB autosuspend globalmente (-1 = nunca suspender).
    # IMPORTANTE: valor 2 significava "suspender após 2s" — causava lag perceptível
    # de 100-500ms no mouse/teclado após breve pausa (wake-up do dispositivo USB).
    "usbcore.autosuspend=-1"

    # Disable mitigations for speed
    "mitigations=off"

    # IOMMU soft mode: NVMe gera IO_PAGE_FAULT no endereço MSI (0xfee00000)
    # com IOMMU hardware. Soft mode elimina esses faults sem impacto real
    # (não usa GPU passthrough / VFIO).
    "iommu=soft"

    # Hugepages: madvise balanceia retenção de memória com perf de apps que usam madvise.
    "transparent_hugepage=madvise"

    # Nvidia
    # NVreg_DynamicPowerManagement=0x02 removido — conflita com finegrained=false e causa freeze no suspend
    "nvidia-drm.fbdev=1"
    "nvidia-drm.modeset=1"

    # AMD
    "amd_pstate=active" # active/guided/passive - active é muito mais rápido e responsivo

    # Roda IRQ handlers em threads de kernel dedicados — garante que eventos USB (mouse/teclado)
    # não são bloqueados por outros IRQ handlers, reduzindo latência de input no Wayland.
    "threadirqs"

    # Containers: reduz contention de timer lock em multicore (vários containers = vários threads)
    "skew_tick=1"

    # Sem zswap: hibernação usa swap em disco; zswap reserva RAM para comprimir swap.
    "zswap.enabled=0"
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
    # Swappiness baixo: o kernel evita swap e prefere RAM + drop de page cache.
    # Use 1 (não 0): com 0 o reclaim de memória anônima fica tão raro que o
    # sistema pode ir direto a OOM sem “avisar” o earlyoom.
    "vm.swappiness" = 1;

    # >100 = kernel despeja dentry/inode cache mais cedo sob pressão (RAM para apps anônimas).
    # Com swappiness 1, isso ajuda a evitar swap enquanto ainda há cache de FS recuperável.
    "vm.vfs_cache_pressure" = 120;

    # Swap readahead: default (3 = 8 páginas) puxa páginas vizinhas do swap
    # especulativamente, causando IO desnecessário. 0 = só traz a página pedida.
    "vm.page-cluster" = 0;

    # NVMe interno aguenta rajadas de escrita muito bem.
    # Limites mais generosos reduzem stalls de CPU por flush prematuro.
    "vm.dirty_ratio" = 10; # flush forçado ao atingir 10% da RAM (~4.8GB em 48GB)
    "vm.dirty_background_ratio" = 5; # flush em background começa aos 5% (~2.4GB)

    # Flush proativo: reduz wakeups e permite que a drive batch writes melhor.
    "vm.dirty_writeback_centisecs" = 1500; # flush a cada 15s ao invés de 5s

    # Desabilita NMI watchdog via sysctl (complementa nmi_watchdog=0 no cmdline).
    "kernel.nmi_watchdog" = 0;

    # Rede: buffers maiores para melhor throughput
    "net.core.netdev_max_backlog" = 16384;
    "net.ipv4.tcp_fastopen" = 3;

    # Reutiliza sockets TIME_WAIT — containers fazendo muitas conexões curtas (HTTP, DB).
    "net.ipv4.tcp_tw_reuse" = 1;

    # userland-proxy=false: DNAT via loopback exige route_localnet para funcionar.
    # Sem isso, nginx (network_mode=host) não consegue alcançar containers via 127.0.0.1.
    "net.ipv4.conf.all.route_localnet" = 1;

    # Containers Go/Node usam mmap intensamente. Default 65530 estoura com 5+ containers.
    "vm.max_map_count" = 1048576;

    # Inotify: múltiplos containers uid 1000 compartilham este limite no host.
    # Com 5+ containers cada um rodando Claude Code + file watchers, 1024 instances
    # Permite containers rootless (Podman) bindarem portas baixas (80, 443, etc.)
    "net.ipv4.ip_unprivileged_port_start" = 0;

    # watermark_scale_factor: default do kernel = 10. Valores *maiores* fazem o
    # kswapd acordar *mais cedo* (mais reclaim). 50 era 5× o default e puxava
    # pressão de memória cedo demais — contribui para swap mesmo com swappiness 1.
    "vm.watermark_scale_factor" = 10;
    # Sem “boost” extra de watermark (comportamento mais previsível sob carga).
    "vm.watermark_boost_factor" = 0;

    # Desabilita compactação proativa de memória — o kernel em background tenta
    # criar hugepages contíguas, causando micro-stalls de dezenas de ms no compositor.
    # Com transparent_hugepage=madvise, só apps que pedem hugepages as recebem.
    "vm.compaction_proactiveness" = 0;

    # Autogroup: agrupa processos da mesma sessão interativa para scheduling.
    # Sem isso, containers em crash loop competem no mesmo nível do DE no CFS.
    # Com scx_lavd isso é parcialmente tratado, mas autogroup adiciona outra camada.
    "kernel.sched_autogroup_enabled" = 1;
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
    SUBSYSTEM=="block", ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"

    # Nuphy Air 75 V3 — permite acesso ao configurador web via Chrome/WebHID
    SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="19f5", ATTR{idProduct}=="1028", MODE="0666"
    KERNEL=="hidraw*", ATTRS{idVendor}=="19f5", ATTRS{idProduct}=="1028", MODE="0666"

    # Desabilita USB autosuspend para dispositivos HID (mouse, teclado) individualmente.
    # usbcore.autosuspend=-1 define o default global, mas drivers de dispositivo podem
    # sobrescrever. Este rule garante power/control=on (nunca suspender) para todos HID.
    SUBSYSTEM=="usb", ATTRS{bInterfaceClass}=="03", TEST=="/sys$devpath/power/control", ATTR{power/control}="on"
    SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{bDeviceClass}=="00", TEST=="/sys$devpath/power/control", ATTR{power/control}="on"
  '';
}
