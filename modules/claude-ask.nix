{ config, pkgs, ... }:
let
  containers = config.local.containers;
  isPodman = containers.engine == "podman";

  user = "pedrinho";
  projectDir = "/home/${user}/nixos";

  enginePkg = if isPodman then pkgs.podman else pkgs.docker;
  composePkg = if isPodman then pkgs.podman-compose else pkgs.docker-compose;
  socketPath = if isPodman then "unix:///run/user/1000/podman/podman.sock" else "unix:///var/run/docker.sock";

  commonEnv = [
    "HOME=/home/${user}"
    "XDG_RUNTIME_DIR=/run/user/1000"
    "DOCKER_HOST=${socketPath}"
    "WAYLAND_DISPLAY=wayland-1"
    "DISPLAY=:0"
    "PATH=${enginePkg}/bin:${composePkg}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.bash}/bin:${pkgs.alacritty}/bin:${pkgs.hyprland}/bin:/run/current-system/sw/bin"
  ];

  askScript = pkgs.writeShellScript "claude-ask-launcher" ''
    set -euo pipefail

    LOCKFILE="/tmp/claude-ask.lock"

    # Guard: se já tá rodando, não abre outro — foca a janela existente
    if [ -f "$LOCKFILE" ]; then
      pid=$(cat "$LOCKFILE" 2>/dev/null || echo "")
      if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        ${pkgs.hyprland}/bin/hyprctl dispatch focuswindow "title:claude-ask" 2>/dev/null || true
        exit 0
      fi
      rm -f "$LOCKFILE"
    fi

    # Abre Alacritty rodando o script dentro
    ${pkgs.alacritty}/bin/alacritty \
      --title "claude-ask" \
      --working-directory ${projectDir} \
      -e ${projectDir}/scripts/claude-ask.sh "$@"
  '';
in {
  # ── Claude Ask (a cada 1 min) ───────────────────────────────────
  systemd.services.claude-ask = {
    description = "Claude Ask — prompt interativo em Alacritty";
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = user;
      Group = "users";
      WorkingDirectory = projectDir;
      ExecStart = "${askScript}";
      TimeoutStartSec = "5min";
      Restart = "no";
      Environment = commonEnv;
    };
  };

  systemd.timers.claude-ask = {
    description = "Abre Claude Ask a cada 1 minuto";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "minutely";
      Persistent = false;
    };
  };
}
