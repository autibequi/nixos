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

    # USB autosuspend: 2s suspende devices USB ociosos, economizando bateria.
    # -1 desabilita completamente — ruim para autonomia de laptop.
    # Se algum periférico travar ou desconectar sozinho, volte para -1.
    "usbcore.autosuspend=2"

    # Desabilita o NMI watchdog — em desktop/laptop não há utilidade prática
    # e ele acorda a CPU periodicamente, gerando wakeups desnecessários.
    "nmi_watchdog=0"

    "iommu=pt"

    # NVMe: APST desligado = disco em PS0 (máx. desempenho). Sem isso throughput cai.
    "nvme_core.default_ps_max_latency_us=0"
    # PCIe ASPM (L1) pode limitar throughput do NVMe; off = link sempre L0.
    "pcie_aspm=off"

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

    # sched_autogroup: agrupa processos do mesmo terminal/sessão e aplica
    # nice diferenciado por grupo — impede que builds pesados (cargo, gradle,
    # flutter) engulam o timeslice das janelas interativas.
    "kernel.sched_autogroup_enabled" = 1;

    # Desabilita NMI watchdog via sysctl (complementa nmi_watchdog=0 no cmdline).
    "kernel.nmi_watchdog" = 0;

    # Compactação de memória proativa em background: reduz stalls de alocação
    # de hugepages ao manter memória contígua disponível antecipadamente.
    # 20 é conservador o suficiente para não interferir com uso interativo.
    "vm.compaction_proactiveness" = 20;
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

  # Governor: schedutil é o correto para laptop.
  # - "performance" é global — mantém o CPU no boost máximo mesmo na bateria,
  #   o que destrói a autonomia. Não há distinção AC/BAT nesse setter.
  # - "schedutil" reage à carga real do scheduler (CFS/SCX) e, combinado com
  #   amd_pstate=active + auto-epp, entrega boost instantâneo quando há carga
  #   E recua rapidamente quando ocioso — o melhor dos dois mundos em laptop.
  # - auto-epp (abaixo) cuida do EPP (energy_performance_preference) por perfil
  #   de energia, tornando o par schedutil+auto-epp equivalente a "performance
  #   no AC, powersave inteligente na bateria" sem nenhum ajuste manual.
  powerManagement.cpuFreqGovernor = "schedutil";

  # AMD Power Management Indication
  # auto-epp ajusta o EPP do amd_pstate automaticamente conforme AC/BAT:
  #   - AC  → energy_performance_preference = "performance"
  #   - BAT → energy_performance_preference = "power" ou "balance_power"
  # Isso substitui o papel do power-profiles-daemon de forma mais leve e
  # sem conflitar com o schedutil + SCX.
  services.auto-epp.enable = true;

  # TRIM periódico para saúde do NVMe interno
  services.fstrim.enable = true;
  services.fstrim.interval = "weekly";

  # NVMe já faz scheduling interno; mq-deadline adiciona latência sem ganho.
  # Forçar "none" iguala ao comportamento típico no Windows e melhora throughput.
  services.udev.extraRules = ''
    SUBSYSTEM=="block", ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
  '';
}
