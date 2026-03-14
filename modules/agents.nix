# =============================================================================
# agents.nix — Configurações de agentes no host (CLAUDINHO, Claude Ask, cron, timers)
# =============================================================================
# Tudo que é agente/agendamento no NixOS: systemd timers + opcional cron.
# =============================================================================

{ config, lib, pkgs, ... }:
let
  containers = config.local.containers;
  isPodman = containers.engine == "podman";

  user = "pedrinho";
  projectDir = "/home/${user}/nixos";
  vaultDir = "/home/${user}/.ovault/Work";

  enginePkg = if isPodman then pkgs.podman else pkgs.docker;
  composePkg = if isPodman then pkgs.podman-compose else pkgs.docker-compose;
  composeBin = if isPodman then "podman-compose" else "docker-compose";
  composeFiles = "-f ${projectDir}/docker-compose.claude.yml"
    + (if isPodman then " -f ${projectDir}/docker-compose.podman.yml" else "");
  compose = "${composePkg}/bin/${composeBin} ${composeFiles}";

  hostSocket = if isPodman then "/run/podman/podman.sock" else "/var/run/docker.sock";
  userSocket = if isPodman then "unix:///run/user/1000/podman/podman.sock" else "unix:///var/run/docker.sock";

  logsDir = "${projectDir}/.ephemeral/logs";

  commonEnv = [
    "HOME=/home/${user}"
    "XDG_RUNTIME_DIR=/run/user/1000"
    "WAYLAND_DISPLAY=wayland-1"
    "PATH=${enginePkg}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.bash}/bin:/run/current-system/sw/bin"
    "CONTAINER_SOCK=${hostSocket}"
  ];

  # Multi-worker dispatch
  mkRunnerScript = { clock, maxWorkers, serviceName }: pkgs.writeShellScript "clau-dispatch-${clock}" ''
    set -euo pipefail
    cd ${projectDir}

    MAX_WORKERS=${toString maxWorkers}
    CLOCK="${clock}"
    LOGFILE="${logsDir}/worker-${clock}.log"

    mkdir -p "${logsDir}"

    # Rotate log if > 500KB
    if [ -f "$LOGFILE" ] && [ "$(stat -c%s "$LOGFILE" 2>/dev/null || echo 0)" -gt 512000 ]; then
      tail -200 "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
    fi

    # Redirect all output to log file (and stdout for journal)
    exec > >(${pkgs.coreutils}/bin/tee -a "$LOGFILE") 2>&1

    if [ ! -f ${vaultDir}/kanban.md ] && [ ! -f ${vaultDir}/scheduled.md ]; then
      echo "[clau:$CLOCK] kanban.md/scheduled.md não encontrados."
      exit 0
    fi

    kanban_cards=$(grep -c '^\- \[' ${vaultDir}/kanban.md 2>/dev/null || echo "0")
    scheduled_cards=$(grep -c '^\- \[' ${vaultDir}/scheduled.md 2>/dev/null || echo "0")
    total=$((kanban_cards + scheduled_cards))
    if [ "$total" -eq 0 ]; then
      echo "[clau:$CLOCK] Sem cards no kanban/scheduled."
      exit 0
    fi

    SERVICE=$( [ "$CLOCK" = "every10" ] && echo "worker-fast" || echo "worker" )

    # Ensure container network exists (compose needs it)
    COMPOSE_PROJECT=$(basename ${projectDir})
    NETWORK="''${COMPOSE_PROJECT}_default"
    if ! ${enginePkg}/bin/${containers.engine} network exists "$NETWORK" 2>/dev/null; then
      echo "[clau:$CLOCK] Criando network $NETWORK..."
      ${enginePkg}/bin/${containers.engine} network create "$NETWORK" 2>/dev/null || true
    fi

    PIDS=()
    for i in $(seq 1 $MAX_WORKERS); do
      WORKER_ID="$CLOCK-$i"

      existing=$(${enginePkg}/bin/${containers.engine} ps --filter "label=com.docker.compose.service=$SERVICE" \
        --filter "label=clau.worker.id=$WORKER_ID" \
        --format "{{.ID}}" 2>/dev/null | head -1)
      if [ -n "$existing" ]; then
        echo "[clau] $WORKER_ID já rodando ($existing) — skip"
        continue
      fi

      echo "[clau] Lançando $WORKER_ID ($CLOCK)..."
      ${compose} run --rm -T \
        -e CLAU_WORKER_ID="$WORKER_ID" \
        -e CLAU_CLOCK="$CLOCK" \
        -l clau.worker.id="$WORKER_ID" \
        $SERVICE /workspace/scripts/clau-runner.sh &
      PIDS+=($!)
    done

    if [ ''${#PIDS[@]} -eq 0 ]; then
      echo "[clau:$CLOCK] Nenhum worker lançado."
      exit 0
    fi

    echo "[clau:$CLOCK] ''${#PIDS[@]} workers lançados."
    for pid in "''${PIDS[@]}"; do
      wait "$pid" 2>/dev/null || true
    done
    echo "[clau:$CLOCK] Done."
  '';

  cleanupScript = pkgs.writeShellScript "clau-cleanup" ''
    cd ${projectDir}
    for dir in vault/_agent/tasks/running/*/; do
      [ -d "$dir" ] || continue
      name=$(basename "$dir")
      source=$(grep '^source=' "$dir/.lock" 2>/dev/null | cut -d= -f2 || echo "pending")
      rm -f "$dir/.lock"
      if [ "$source" = "recurring" ]; then
        rm -rf "$dir"
        echo "[cleanup] $name (recurring) removed"
      else
        mv "$dir" "vault/_agent/tasks/pending/$name" 2>/dev/null || rm -rf "$dir"
        echo "[cleanup] $name → pending/"
      fi
    done
    rm -f .ephemeral/.kanban.lock .ephemeral/locks/*.lock
  '';

  heavyRunner = mkRunnerScript { clock = "every60"; maxWorkers = 2; serviceName = "worker"; };
  fastRunner = mkRunnerScript { clock = "every10"; maxWorkers = 1; serviceName = "worker-fast"; };

  commonEnvAsk = [
    "HOME=/home/${user}"
    "XDG_RUNTIME_DIR=/run/user/1000"
    "DOCKER_HOST=${userSocket}"
    "WAYLAND_DISPLAY=wayland-1"
    "DISPLAY=:0"
    "PATH=${enginePkg}/bin:${composePkg}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.bash}/bin:${pkgs.alacritty}/bin:${pkgs.hyprland}/bin:/run/current-system/sw/bin"
  ];

  askScript = pkgs.writeShellScript "claude-ask-launcher" ''
    set -euo pipefail
    LOCKFILE="/tmp/claude-ask.lock"
    if [ -f "$LOCKFILE" ]; then
      pid=$(cat "$LOCKFILE" 2>/dev/null || echo "")
      if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        ${pkgs.hyprland}/bin/hyprctl dispatch focuswindow "title:claude-ask" 2>/dev/null || true
        exit 0
      fi
      rm -f "$LOCKFILE"
    fi
    ${pkgs.alacritty}/bin/alacritty \
      --title "claude-ask" \
      --working-directory ${projectDir} \
      -e ${projectDir}/scripts/claude-ask.sh "$@"
  '';
in {
  options.local.agents = lib.mkOption {
    type = lib.types.submodule {
      options = {
        claudeAsk = {
          enable = lib.mkEnableOption "timer Claude Ask (abre Alacritty com prompt a cada minuto)";
        };
      };
    };
    default = { };
    description = "Opções de agentes no host (CLAUDINHO, Claude Ask, cron).";
  };

  config = lib.mkMerge [
    {
  # ---------------------------------------------------------------------------
  # Cron (agentes) — jobs periódicos via cron; adicione entradas aqui se quiser
  # ---------------------------------------------------------------------------
  # services.cron.systemCronJobs = [
  #   # "0 * * * * ${user} ${projectDir}/scripts/meu-agent.sh"
  # ];

  # ---------------------------------------------------------------------------
  # CLAUDINHO — Worker every60 (a cada hora)
  # ---------------------------------------------------------------------------
  systemd.services.claude-autonomous = {
    description = "CLAUDINHO every60 task runner";
    after = [ "network-online.target" ];
    conflicts = [ "claude-autonomous-reset.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = user;
      Group = "users";
      WorkingDirectory = projectDir;
      ExecStart = "${heavyRunner}";
      ExecStopPost = "${cleanupScript}";
      TimeoutStartSec = "45min";
      TimeoutStopSec = "2min";
      Restart = "no";
      Environment = commonEnv;
    };
  };

  systemd.timers.claude-autonomous = {
    description = "Run CLAUDINHO every60 tasks";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };

  # ---------------------------------------------------------------------------
  # CLAUDINHO — Worker every10 (a cada 10 min)
  # ---------------------------------------------------------------------------
  systemd.services.claude-autonomous-fast = {
    description = "CLAUDINHO every10 task runner";
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = user;
      Group = "users";
      WorkingDirectory = projectDir;
      ExecStart = "${fastRunner}";
      ExecStopPost = "${cleanupScript}";
      TimeoutStartSec = "5min";
      TimeoutStopSec = "1min";
      Restart = "no";
      Environment = commonEnv;
    };
  };

  systemd.timers.claude-autonomous-fast = {
    description = "Run CLAUDINHO every10 tasks (a cada 10 min)";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/10";  # 0, 10, 20, 30, 40, 50
      Persistent = true;
    };
  };

  # ---------------------------------------------------------------------------
  # CLAUDINHO — Reset (tasks presas)
  # ---------------------------------------------------------------------------
  systemd.services.claude-autonomous-reset = {
    description = "Reset stuck CLAUDINHO tasks";
    conflicts = [ "claude-autonomous.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = user;
      Group = "users";
      WorkingDirectory = projectDir;
      ExecStart = pkgs.writeShellScript "clau-hard-reset" ''
        cd ${projectDir}
        echo "[reset] Parando workers..."
        ${compose} kill worker 2>/dev/null || true
        ${compose} kill worker-fast 2>/dev/null || true
        ${compose} rm -f worker worker-fast 2>/dev/null || true
        ${cleanupScript}
      '';
      Environment = commonEnv;
    };
  };
    }

    # -------------------------------------------------------------------------
    # Claude Ask — prompt em Alacritty (opcional; local.agents.claudeAsk.enable)
    # -------------------------------------------------------------------------
    (lib.mkIf (config.local.agents.claudeAsk.enable or false) {
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
          Environment = commonEnvAsk;
        };
      };

      systemd.timers.claude-ask = {
        description = "Claude Ask (a cada 1 min)";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "minutely";
          Persistent = false;
        };
      };
    })
  ];
}
