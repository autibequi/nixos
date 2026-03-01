{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Disable Evil Printer
  services.printing.enable = false;

  # fwupd
  services.fwupd.enable = true;

  # Tailscale (useRoutingFeatures = "client" para aceitar rotas de subnet do Pi sem drop por rp_filter)
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };
  networking.firewall.checkReversePath = "loose";
}
