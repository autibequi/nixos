{ config, pkgs, ... }:

{
  # Enable the Cosmic Desktop Environment
  services.xserver.desktopManager.cosmic.enable = true;
  services.xserver.desktopManager.cosmic.package = pkgs.cosmic; # Use the latest version of Cosmic DE

  # # Additional cool stuff
  # services.xserver.desktopManager.cosmic.dock.enable = true;
  # services.xserver.desktopManager.cosmic.workspaces.enable = true;
  # services.xserver.desktopManager.cosmic.launcher.enable = true;
  # services.xserver.desktopManager.cosmic.notifications.enable = true;
  # services.xserver.desktopManager.cosmic.widgets.enable = true;
  # services.xserver.desktopManager.cosmic.extensions.enable = true;
  # services.xserver.desktopManager.cosmic.theme = "cosmic-dark";
  # services.xserver.desktopManager.cosmic.hotCorners.enable = true;
  # services.xserver.desktopManager.cosmic.gestures.enable = true;
}