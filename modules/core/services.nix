{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Disable Evil Printer
  services.printing.enable = false;

  # UPower: battery/power info via DBus. Chrome e outros apps chamam org.freedesktop.UPower;
  # sem o serviço, falha "ServiceUnknown: The name is not activatable" e pode bloquear no launch.
  services.upower.enable = true;

  # fwupd — desativado (firmware update é manual, daemon rodando 24/7 não faz sentido)
  services.fwupd.enable = false;

  # Flatpak — desativado (portal daemon desnecessário se tudo vem do Nix)
  services.flatpak.enable = false;

  # Tailscale (useRoutingFeatures = "client" para aceitar rotas de subnet do Pi sem drop por rp_filter)
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };
  networking.firewall.checkReversePath = "loose";

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
}
