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

  # fwupd
  services.fwupd.enable = true;

  # Flatpak
  services.flatpak.enable = true;

  # Tailscale (useRoutingFeatures = "client" para aceitar rotas de subnet do Pi sem drop por rp_filter)
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };
  networking.firewall.checkReversePath = "loose";
}
