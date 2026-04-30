{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Timeout global de stop: default do systemd é 90s, reduzido para 15s
  # para evitar que qualquer serviço bloqueie o shutdown por muito tempo.
  systemd.settings.Manager.DefaultTimeoutStopSec = "15s";

  # Disable Evil Printer
  services.printing.enable = false;

  # NetworkManager-wait-online: bloqueia o boot por ~8s esperando conectividade.
  # Desnecessário para desktop — tudo que depende de rede usa wants, não requires.
  systemd.services.NetworkManager-wait-online.enable = false;

  # ModemManager: gerencia modems 3G/4G — inútil sem modem celular.
  # Consome RAM e faz polling de USB no boot.
  systemd.services.ModemManager.enable = false;

  # UPower: battery/power info via DBus. Chrome e outros apps chamam org.freedesktop.UPower;
  # sem o serviço, falha "ServiceUnknown: The name is not activatable" e pode bloquear no launch.
  services.upower.enable = true;

  # udisks2: automontagem de dispositivos removíveis (pendrives, HDs externos).
  # gvfs: expõe udisks2 via DBus para apps GTK/Nautilus montarem automaticamente.
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # fwupd — desativado (firmware update é manual, daemon rodando 24/7 não faz sentido)
  services.fwupd.enable = false;

  # Flatpak — desativado (portal daemon desnecessário se tudo vem do Nix)
  services.flatpak.enable = false;

  # Tailscale (useRoutingFeatures = "client" para aceitar rotas de subnet do Pi sem drop por rp_filter)
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };
  # networking.firewall.checkReversePath = "loose"; # só necessário com tailscale ativo

  # SSH — acessível apenas na rede local (192.168.0.0/16)
  services.openssh = {
    enable = true;
    openFirewall = false; # não abre publicamente
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -s 192.168.0.0/16 -p tcp --dport 22 -j nixos-fw-accept
  '';

  # LM Studio API Server (disabled — lms binary segfaults, needs manual install)
  services.lmstudio.enable = false;

  # WiFi sem power saving — elimina spikes de latência de 100-400ms
  networking.networkmanager.wifi.powersave = false;

  # irqbalance desabilitado: NVMe usa MSI-X com afinidade fixa (1 queue/core),
  # irqbalance não consegue mover e gera 16 warnings. Com SCX lavd + NVMe MSI-X,
  # a distribuição de IRQs já é ótima sem intervenção.
  services.irqbalance.enable = false;

  # TLP desabilitado explicitamente: conflita com auto-epp (ambos tentam
  # gerenciar EPP do amd_pstate) e adicionava ~762ms ao boot.
  # auto-epp em kernel.nix já cobre AC/BAT switching.
  services.tlp.enable = false;

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
  # enableUserServices: cobre a sessão do usuário onde nomad/podman rodam.
  systemd.oomd = {
    enable = true;
    enableUserServices = true;
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
