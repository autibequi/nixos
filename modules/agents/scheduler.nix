# =============================================================================
# scheduler.nix — Unified systemd timer + service for CLAUDINHO scheduler
# =============================================================================
# Single 10-min timer → clau-scheduler.sh → decides what to run → 1 container
# Replaces the previous 3-timer setup (every10/every60/every240).
# =============================================================================

{ config, lib, pkgs, ... }:
let
  containers = config.local.containers;
  isPodman = containers.engine == "podman";

  user = config.local.agents.claudinho.user or "pedrinho";
  projectDir = "/home/${user}/nixos";
  vaultDir = "/home/${user}/.ovault";

  enginePkg = if isPodman then pkgs.podman else pkgs.docker;
  composePkg = if isPodman then pkgs.podman-compose else pkgs.docker-compose;
  composeBin = if isPodman then "${pkgs.podman-compose}/bin/podman-compose" else "${pkgs.docker-compose}/bin/docker-compose";
  composeFiles = "-f ${projectDir}/docker-compose.claude.yml"
    + (if isPodman then " -f ${projectDir}/docker-compose.podman.yml" else "");

  hostSocket = if isPodman then "/run/podman/podman.sock" else "/var/run/docker.sock";

  logsDir = "${projectDir}/.ephemeral/logs";

  cfgClaudinho = config.local.agents.claudinho or { };
  tickBudget = cfgClaudinho.tickBudgetSeconds or 540;

  commonEnv = [
    "HOME=/home/${user}"
    "XDG_RUNTIME_DIR=/run/user/1000"
    "WAYLAND_DISPLAY=wayland-1"
    "PATH=${enginePkg}/bin:${composePkg}/bin:${pkgs.python3}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.bash}/bin:${pkgs.util-linux}/bin:/run/current-system/sw/bin"
    "CONTAINER_SOCK=${hostSocket}"
  ];

  schedulerScript = pkgs.writeShellScript "clau-scheduler-dispatch" ''
    set -euo pipefail
    cd ${projectDir}

    export CLAU_PROJECT_DIR="${projectDir}"
    export CLAU_VAULT_DIR="${vaultDir}"
    export CLAU_TICK_BUDGET="${toString tickBudget}"
    export CLAU_COMPOSE_BIN="${composeBin} ${composeFiles}"
    export CLAU_COMPOSE_FILES=""

    # Ensure container network exists
    COMPOSE_PROJECT=$(basename ${projectDir})
    NETWORK="''${COMPOSE_PROJECT}_default"
    if ! ${enginePkg}/bin/${containers.engine} network exists "$NETWORK" 2>/dev/null; then
      echo "[scheduler] Creating network $NETWORK..."
      ${enginePkg}/bin/${containers.engine} network create "$NETWORK" 2>/dev/null || true
    fi

    exec ${pkgs.bash}/bin/bash ${projectDir}/scripts/clau-scheduler.sh
  '';

  cleanupScript = pkgs.writeShellScript "clau-cleanup" ''
    for dir in ${vaultDir}/_agent/tasks/running/*/; do
      [ -d "$dir" ] || continue
      name=$(basename "$dir")
      source=$(grep '^source=' "$dir/.lock" 2>/dev/null | cut -d= -f2 || echo "pending")
      rm -f "$dir/.lock"
      if [ "$source" = "recurring" ]; then
        rm -rf "$dir"
        echo "[cleanup] $name (recurring) removed"
      else
        mv "$dir" "${vaultDir}/_agent/tasks/pending/$name" 2>/dev/null || rm -rf "$dir"
        echo "[cleanup] $name → pending/"
      fi
    done
    rm -f ${projectDir}/.ephemeral/.kanban.lock ${projectDir}/.ephemeral/locks/*.lock
  '';
in {
  config = {
    # ─────────────────────────────────────────────────────────────────────────
    # CLAUDINHO — Unified scheduler (every 10 min)
    # ─────────────────────────────────────────────────────────────────────────
    systemd.services.claude-scheduler = {
      description = "CLAUDINHO unified task scheduler";
      after = [ "network-online.target" ];
      conflicts = [ "claude-scheduler-reset.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = user;
        Group = "users";
        WorkingDirectory = projectDir;
        ExecStart = "${schedulerScript}";
        ExecStopPost = "${cleanupScript}";
        TimeoutStartSec = "12min";
        TimeoutStopSec = "2min";
        Restart = "no";
        Environment = commonEnv;
      };
    };

    systemd.timers.claude-scheduler = {
      description = "Run CLAUDINHO scheduler every 10 min";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*:0/10";
        Persistent = true;
      };
    };

    # ─────────────────────────────────────────────────────────────────────────
    # CLAUDINHO — Reset (stuck tasks)
    # ─────────────────────────────────────────────────────────────────────────
    systemd.services.claude-scheduler-reset = {
      description = "Reset stuck CLAUDINHO tasks";
      conflicts = [ "claude-scheduler.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = user;
        Group = "users";
        WorkingDirectory = projectDir;
        ExecStart = pkgs.writeShellScript "clau-hard-reset" ''
          cd ${projectDir}
          echo "[reset] Stopping workers..."
          ${composeBin} ${composeFiles} kill worker 2>/dev/null || true
          ${composeBin} ${composeFiles} rm -f worker 2>/dev/null || true
          ${cleanupScript}
        '';
        Environment = commonEnv;
      };
    };
  };
}
