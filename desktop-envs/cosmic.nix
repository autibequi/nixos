{ config, pkgs, ... }:

{
  # Desktop Environment
  services.xserver.enable = true;
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "alt-intl";
  };
}