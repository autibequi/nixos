{ pkgs, hyprlandWaybar, config, ... }:
let
  warpPkg = config.services.cloudflare-warp.package or pkgs.cloudflare-warp;
  # systemd user services não herdam o PATH completo do shell nem do QML Process{}.
  userServicePath = "PATH=%h/.local/bin:%h/.nix-profile/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin";
in
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

  # warp-taskbar — ícone Cloudflare WARP na systray do waybar.
  # O .desktop de autostart (com.cloudflare.WarpTaskbar) depende de
  # graphical-session.target, que UWSM não ativa aqui — sobe via waybar/autostart.
  # BindReadOnlyPaths: warp-taskbar procura assets em /usr/share/warp (Nix store).
  systemd.user.services.warp-taskbar = {
    description = "Cloudflare Zero Trust tray icon";
    after = [ "dbus.socket" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${warpPkg}/bin/warp-taskbar";
      Restart = "on-failure";
      RestartSec = 5;
      BindReadOnlyPaths = "${warpPkg}:/usr:";
    };
  };

  # Waybar — status bar. Systemd user service pra reiniciar sozinho se cair.
  # Sem isso, pkill waybar (no hotplug de monitor) ou crash deixa a barra sumida.
  # Substitui o `hl.exec_cmd(L.build("waybar"))` do autostart.lua.
  systemd.user.services.waybar = {
    description = "Waybar status bar";
    after = [
      "graphical-session.target"
      "warp-taskbar.service"
    ];
    requires = [ "warp-taskbar.service" ];
    wantedBy = [ "graphical-session.target" ];
    unitConfig = {
      StartLimitBurst = 5;
      StartLimitIntervalSec = 30;
    };
    serviceConfig = {
      ExecStart = "${hyprlandWaybar}/bin/waybar --config %h/.config/waybar/config.jsonc --style %h/.config/waybar/style.css";
      Restart = "on-failure";
      RestartSec = 2;
      # %h/.local/bin necessário para `yaa` (custom/claude-usage). Systemd user services
      # não herdam o PATH completo do shell; adicionar manualmente os caminhos críticos.
      Environment = userServicePath;
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
      # QML Process{} não herda um PATH útil do systemd user; sem isso o journal
      # mostra falhas para `sh`, `brightnessctl`, `hyprctl`, etc.
      Environment = userServicePath;
    };
  };

  # Hyprshade — o schedule em ~/.config/hyprshade/config.toml (blue-light-filter
  # 19:00–06:00) existia mas nada o disparava. Timer nos dois boundaries roda
  # `hyprshade auto`; escolha manual (walker `s:` / SUPER+Del) sobrevive fora deles.
  # ponytail: 19:00 fixo — pôr-do-sol real exigiria wlsunset/geoclue.
  systemd.user.services.hyprshade-auto = {
    description = "Apply scheduled hyprshade shader";
    serviceConfig = {
      Type = "oneshot";
      # shader-set.sh (não hyprshade): o fork Lua rejeita `hyprctl keyword`
      ExecStart = "${pkgs.bash}/bin/bash %h/.config/hypr/shader-set.sh auto";
      Environment = userServicePath;
    };
  };
  systemd.user.timers.hyprshade-auto = {
    description = "Hyprshade schedule boundaries";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = [ "*-*-* 19:00:00" "*-*-* 06:00:00" ];
      Persistent = true;
    };
  };

  # SwayNC — notification daemon. Antes era spawn solto no autostart.lua: quando
  # crashava (7 coredumps em 28/06) ficava sem notificações até relogin.
  systemd.user.services.swaync = {
    description = "SwayNC notification daemon";
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    unitConfig = {
      StartLimitBurst = 5;
      StartLimitIntervalSec = 30;
    };
    serviceConfig = {
      ExecStart = "${pkgs.swaynotificationcenter}/bin/swaync";
      Restart = "on-failure";
      RestartSec = 2;
      Environment = userServicePath;
    };
  };

  # Elephant — backend de providers do Walker (apps, calc, files, clipboard, etc.).
  # Precisa rodar como user service pra herdar ambiente Wayland/session correto.
  systemd.user.services.elephant = {
    description = "Elephant data provider service";
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    unitConfig = {
      StartLimitBurst = 5;
      StartLimitIntervalSec = 30;
    };
    serviceConfig = {
      ExecStart = "${pkgs.elephant}/bin/elephant";
      Restart = "on-failure";
      RestartSec = 5;
      Environment = userServicePath;
    };
  };

  # Walker — app launcher / command palette. Rodar como GApplication service deixa
  # o MOD3+Space abrir quase instantâneo e evita pagar cold start a cada chamada.
  systemd.user.services.walker = {
    description = "Walker application launcher service";
    after = [
      "graphical-session.target"
      "elephant.service"
    ];
    wants = [ "elephant.service" ];
    wantedBy = [ "graphical-session.target" ];
    unitConfig = {
      StartLimitBurst = 5;
      StartLimitIntervalSec = 30;
    };
    serviceConfig = {
      ExecStart = "${pkgs.walker}/bin/walker --gapplication-service";
      Restart = "on-failure";
      RestartSec = 2;
      Environment = userServicePath;
    };
  };
}
