{ ... }:
{
  networking = {
    hostName = "nomad";
    networkmanager.enable = true;
  };

  # WiFi sem power saving — elimina spikes de latência de 100-400ms
  networking.networkmanager.wifi.powersave = false;

  # NetworkManager-wait-online: bloqueia o boot por ~8s esperando conectividade.
  # Desnecessário para desktop — tudo que depende de rede usa wants, não requires.
  systemd.services.NetworkManager-wait-online.enable = false;

  # wpa_supplicant trava por ~12s no shutdown aguardando timeout interno do nl80211
  # ("send_event_marker failed: Source based routing not supported").
  # A máquina vai desligar de qualquer forma — não precisa esperar deauth limpo.
  systemd.services.wpa_supplicant.serviceConfig.TimeoutStopSec = "3s";

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
      MaxAuthTries = 3;
      LoginGraceTime = 30;
    };
  };
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -s 192.168.0.0/16 -p tcp --dport 22 -j nixos-fw-accept
  '';
}
