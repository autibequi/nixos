# =============================================================================
# scheduler.nix — Systemd timers + services para workers CLAUDINHO
# =============================================================================
# every10 (fast), every60 (heavy), every240 (slow), reset
# =============================================================================

{ config, lib, pkgs, ... }:
let
  containers = config.local.containers;
  isPodman = containers.engine == "podman";

  user = config.local.agents.claudinho.user or "pedrinho";
  projectDir = "/home/${user}/nixos";
  vaultDir = "/home/${user}/.ovault/Work";

  enginePkg = if isPodman then pkgs.podman else pkgs.docker;
  composePkg = if isPodman then pkgs.podman-compose else pkgs.docker-compose;
  composeBin = if isPodman then "podman-compose" else "docker-compose";
  composeFiles = "-f ${projectDir}/docker-compose.claude.yml"
    + (if isPodman then " -f ${projectDir}/docker-compose.podman.yml" else "");
  compose = "${composePkg}/bin/${composeBin} ${composeFiles}";

  hostSocket = if isPodman then "/run/podman/podman.sock" else "/var/run/docker.sock";

  logsDir = "${projectDir}/.ephemeral/logs";
  dispatchLockDir = "${projectDir}/.ephemeral/locks";

  cfgClaudinho = config.local.agents.claudinho or { };
  maxWorkersFast = cfgClaudinho.maxWorkersFast or 1;
  maxWorkersHeavy = cfgClaudinho.maxWorkersHeavy or 1;
  maxWorkersSlow = cfgClaudinho.maxWorkersSlow or 1;

  commonEnv = [
    "HOME=/home/${user}"
    "XDG_RUNTIME_DIR=/run/user/1000"
    "WAYLAND_DISPLAY=wayland-1"
    "PATH=${enginePkg}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.bash}/bin:/run/current-system/sw/bin"
    "CONTAINER_SOCK=${hostSocket}"
  ];

  # Multi-worker dispatch — controle de custo: maxConcurrentWorkers no sistema, maxWorkers por clock
  mkRunnerScript = { clock, maxWorkers, serviceName }: pkgs.writeShellScript "clau-dispatch-${clock}" ''
    set -euo pipefail
    cd ${projectDir}

    MAX_WORKERS=${toString maxWorkers}
    CLOCK="${clock}"
    LOGFILE="${logsDir}/worker-${clock}.log"
    LOCKFILE="${dispatchLockDir}/dispatch-${clock}.lock"

    mkdir -p "${logsDir}" "${dispatchLockDir}"

    # Uma única instância por clock (evita reentrada do mesmo timer)
    exec 200>"$LOCKFILE"
    if ! ${pkgs.util-linux}/bin/flock -n 200; then
      echo "[clau:$CLOCK] Outra instância deste clock — skip."
      exit 0
    fi

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

  heavyRunner = mkRunnerScript { clock = "every60"; maxWorkers = maxWorkersHeavy; serviceName = "worker"; };
  fastRunner = mkRunnerScript { clock = "every10"; maxWorkers = maxWorkersFast; serviceName = "worker-fast"; };
  slowRunner = mkRunnerScript { clock = "every240"; maxWorkers = maxWorkersSlow; serviceName = "worker"; };
in {
  config = {
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
        OnCalendar = "*:0/10";
        Persistent = true;
      };
    };

    # ---------------------------------------------------------------------------
    # CLAUDINHO — Worker every240 (a cada 4 horas)
    # ---------------------------------------------------------------------------
    systemd.services.claude-autonomous-slow = {
      description = "CLAUDINHO every240 task runner";
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = user;
        Group = "users";
        WorkingDirectory = projectDir;
        ExecStart = "${slowRunner}";
        ExecStopPost = "${cleanupScript}";
        TimeoutStartSec = "45min";
        TimeoutStopSec = "2min";
        Restart = "no";
        Environment = commonEnv;
      };
    };

    systemd.timers.claude-autonomous-slow = {
      description = "Run CLAUDINHO every240 tasks (a cada 4 horas)";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 0/4:00:00";
        Persistent = true;
      };
    };

    # ---------------------------------------------------------------------------
    # CLAUDINHO — Reset (tasks presas)
    # ---------------------------------------------------------------------------
    systemd.services.claude-autonomous-reset = {
      description = "Reset stuck CLAUDINHO tasks";
      conflicts = [ "claude-autonomous.service" "claude-autonomous-fast.service" "claude-autonomous-slow.service" ];
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
  };
}
