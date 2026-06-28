{ pkgs, ... }:
{
  # substituído pelo OSD in-house (hypr-shell Onda 2)
  # SwayOSD — overlay visual pra volume/brilho/caps lock.
  # NixOS não tem módulo `services.swayosd`; subimos o daemon como systemd
  # user service. `swayosd-client --output-volume/--brightness/--caps-lock`
  # fala com ele via dbus. Backend opcional pra caps-lock LED roda como
  # systemd system service (não habilitado aqui — caps via bind no Hyprland).
  # systemd.user.services.swayosd = {
  #   description = "SwayOSD server (volume/brightness/caps OSD)";
  #   after = [ "graphical-session.target" ];
  #   wantedBy = [ "graphical-session.target" ];
  #   serviceConfig = {
  #     ExecStart = "${pkgs.swayosd}/bin/swayosd-server";
  #     Restart = "on-failure";
  #     RestartSec = 2;
  #   };
  # };

  # hyprpolkitagent tem Restart=on-failure no unit original. Quando Hyprland morre
  # (ex: nixos-rebuild switch mata serviços gráficos), o agent reinicia sem
  # WAYLAND_DISPLAY → Qt6 explode com SIGABRT → loop infinito de crashes.
  # StartLimitBurst=3 deixa tentar 3x antes de desistir, quebrando o loop.
  # ATENÇÃO: definir systemd.user.services.* em NixOS gera um .service COMPLETO em
  # /etc/systemd/user/ que SUBSTITUI o bundled unit do pacote — ExecStart é obrigatório.
  systemd.user.services.hyprpolkitagent = {
    description = "Hyprland Polkit Authentication Agent";
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    unitConfig = {
      StartLimitBurst = 3;
      StartLimitIntervalSec = 30;
    };
    serviceConfig = {
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # Waybar — status bar. Systemd user service pra reiniciar sozinho se cair.
  # Sem isso, pkill waybar (no hotplug de monitor) ou crash deixa a barra sumida.
  # Substitui o `hl.exec_cmd(L.build("waybar"))` do autostart.lua.
  systemd.user.services.waybar = {
    description = "Waybar status bar";
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    unitConfig = {
      StartLimitBurst = 5;
      StartLimitIntervalSec = 30;
    };
    serviceConfig = {
      ExecStart = "${pkgs.waybar}/bin/waybar --config %h/.config/waybar/config.jsonc --style %h/.config/waybar/style.css";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  # Quickshell — shell in-house (overview, clock, power menu, OSD, notif, switcher).
  # Subido como systemd user service pra reiniciar sozinho se cair — sem isso o `qs`
  # morre (ex: spawn pendurado no terminal) e TODOS os módulos somem junto.
  # Substitui o `hl.exec_cmd(L.build("qs"))` do autostart.lua (comentado lá pra não duplicar).
  # StartLimitBurst quebra crash-loop caso um módulo QML falhe no load.
  systemd.user.services.quickshell = {
    description = "Quickshell (in-house Wayland shell)";
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    unitConfig = {
      StartLimitBurst = 5;
      StartLimitIntervalSec = 30;
    };
    serviceConfig = {
      ExecStart = "${pkgs.quickshell}/bin/qs";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
