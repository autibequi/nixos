{ ... }:
{
  # ── Limites de recursos ────────────────────────────────────────────────────

  # Limites para Podman rootless com múltiplos containers simultâneos.
  # (fs.file-max e os tunings de inotify ficam no sysctl em boot/kernel.nix.)
  security.pam.loginLimits = [
    { domain = "*"; type = "soft"; item = "nofile"; value = "65536"; }
    { domain = "*"; type = "hard"; item = "nofile"; value = "65536"; }
  ];

  # Timeout global de stop: default do systemd é 90s, reduzido para 15s
  # para evitar que qualquer serviço bloqueie o shutdown por muito tempo.
  systemd.settings.Manager.DefaultTimeoutStopSec = "15s";

  # ── Schedulers / energia auxiliares ────────────────────────────────────────

  # irqbalance desabilitado: NVMe usa MSI-X com afinidade fixa (1 queue/core),
  # irqbalance não consegue mover e gera 16 warnings. Com SCX lavd + NVMe MSI-X,
  # a distribuição de IRQs já é ótima sem intervenção.
  services.irqbalance.enable = false;

  # TLP desabilitado explicitamente: conflita com auto-epp (ambos tentam
  # gerenciar EPP do amd_pstate) e adicionava ~762ms ao boot.
  # auto-epp em boot/kernel.nix já cobre AC/BAT switching.
  services.tlp.enable = false;

  # ── Journald ───────────────────────────────────────────────────────────────

  # Journald: rate limit agressivo para evitar que crash loops (ex: container
  # sem env var) inundem o journal com milhares de linhas/segundo, comendo
  # CPU do journald e RAM do buffer — causa direta de DE sluggish sob crash loops.
  services.journald.extraConfig = ''
    RateLimitInterval=10s
    RateLimitBurst=500
    SystemMaxUse=2G
    RuntimeMaxUse=512M
  '';

  # ── Isolamento DE vs processos de trabalho ─────────────────────────────────

  # systemd-oomd: mata o cgroup inteiro que causa pressão PSI antes do sistema
  # ficar inresponsivo. Complementa earlyoom (que mata processo a processo):
  # oomd detecta contention de CPU/IO/memória por cgroup e elimina o grupo
  # culpado (ex: container em crash loop) de forma cirúrgica.
  # enableUserSlices: cobre a sessão do usuário onde nomad/podman rodam.
  systemd.oomd = {
    enable = true;
    enableUserSlices = true;
  };

  # Eleva peso de CPU e IO da sessão do usuário (user.slice) vs serviços de sistema.
  # CPUWeight default = 100. Com 400, o DE recebe 4x mais CPU quando há contention
  # contra qualquer serviço de sistema — garantia estrutural de responsividade.
  systemd.slices."user" = {
    sliceConfig = {
      CPUWeight = 400;
      IOWeight = 400;
    };
  };
}
