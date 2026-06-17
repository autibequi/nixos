{ lib, pkgs, ... }:
let
  # Mesmo conteúdo para qualquer DESKTOP que o xdg-desktop-portal procure primeiro
  # (ex.: XDG_CURRENT_DESKTOP=uwsm:Hyprland → lê uwsm-portals.conf antes de hyprland).
  hyprPortalPreferred = ''
    [preferred]
    default=hyprland;gtk
    org.freedesktop.impl.portal.Settings=gtk
  '';
in
{
  # sinais do sistema como color-scheme (dark/light), file picker, screen share
  xdg.portal = {
    enable = true;
    # mkForce evita duplicata: programs.hyprland (withUWSM) também adiciona hyprland portal
    extraPortals = lib.mkForce [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk # handles Settings portal (color-scheme)
    ];
    config = {
      # Para sessões Hyprland: hyprland portal primeiro, gtk como fallback
      hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
        # Settings (color-scheme dark/light) — só gtk implementa
        "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
      };
      # Fallback: sem ficheiro *-portals.conf específico, ou último na lista DE
      common = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
      };
    };
  };

  # programs.hyprland / pacotes podem instalar hyprland-portals.conf minimalista.
  # Garantimos Settings→gtk para hyprland e uwsm (ver hyprPortalPreferred).
  environment.etc = {
    "xdg/xdg-desktop-portal/hyprland-portals.conf".text = lib.mkForce hyprPortalPreferred;
    "xdg/xdg-desktop-portal/uwsm-portals.conf".text = lib.mkForce hyprPortalPreferred;
  };
}
