{ pkgs, ... }:
let
  user = "pedrinho";
  projectDir = "/home/${user}/nixos";
  vaultDir = "/home/${user}/.ovault/Work";
  compose = "${pkgs.podman-compose}/bin/podman-compose -f ${projectDir}/docker-compose.claude.yml";

  logsDir = "${projectDir}/.ephemeral/logs";

  commonEnv = [
    "HOME=/home/${user}"
    "XDG_RUNTIME_DIR=/run/user/1000"
    "DOCKER_HOST=unix:///run/user/1000/podman/podman.sock"
    "WAYLAND_DISPLAY=wayland-1"
    "PATH=${pkgs.podman}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.bash}/bin:/run/current-system/sw/bin"
  ];

  # Multi-worker dispatch
  mkRunnerScript = { tier, maxWorkers, serviceName }: pkgs.writeShellScript "clau-dispatch-${tier}" ''
    set -euo pipefail
    cd ${projectDir}

    MAX_WORKERS=${toString maxWorkers}
    TIER="${tier}"
    LOGFILE="${logsDir}/worker-${tier}.log"

    mkdir -p "${logsDir}"

    # Rotate log if > 500KB
    if [ -f "$LOGFILE" ] && [ "$(stat -c%s "$LOGFILE" 2>/dev/null || echo 0)" -gt 512000 ]; then
      tail -200 "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
    fi

    # Redirect all output to log file (and stdout for journal)
    exec > >(${pkgs.coreutils}/bin/tee -a "$LOGFILE") 2>&1

    if [ ! -f ${vaultDir}/kanban.md ]; then
      echo "[clau:$TIER] kanban.md não encontrado."
      exit 0
    fi

    backlog=$(grep -c '^\- \[' ${vaultDir}/kanban.md 2>/dev/null || echo "0")
    if [ "$backlog" -eq 0 ]; then
      echo "[clau:$TIER] Sem cards no kanban."
      exit 0
    fi

    SERVICE=$( [ "$TIER" = "fast" ] && echo "worker-fast" || echo "worker" )

    # Ensure podman network exists (compose needs it)
    COMPOSE_PROJECT=$(basename ${projectDir})
    NETWORK="''${COMPOSE_PROJECT}_default"
    if ! ${pkgs.podman}/bin/podman network exists "$NETWORK" 2>/dev/null; then
      echo "[clau:$TIER] Criando network $NETWORK..."
      ${pkgs.podman}/bin/podman network create "$NETWORK" 2>/dev/null || true
    fi

    PIDS=()
    for i in $(seq 1 $MAX_WORKERS); do
      WORKER_ID="$TIER-$i"

      existing=$(${pkgs.podman}/bin/podman ps --filter "label=com.docker.compose.service=$SERVICE" \
        --filter "label=clau.worker.id=$WORKER_ID" \
        --format "{{.ID}}" 2>/dev/null | head -1)
      if [ -n "$existing" ]; then
        echo "[clau] $WORKER_ID já rodando ($existing) — skip"
        continue
      fi

      echo "[clau] Lançando $WORKER_ID ($TIER)..."
      ${compose} run --rm -T \
        -e CLAU_WORKER_ID="$WORKER_ID" \
        -e CLAU_TIER="$TIER" \
        -l clau.worker.id="$WORKER_ID" \
        $SERVICE /workspace/scripts/clau-runner.sh &
      PIDS+=($!)
    done

    if [ ''${#PIDS[@]} -eq 0 ]; then
      echo "[clau:$TIER] Nenhum worker lançado."
      exit 0
    fi

    echo "[clau:$TIER] ''${#PIDS[@]} workers lançados."
    for pid in "''${PIDS[@]}"; do
      wait "$pid" 2>/dev/null || true
    done
    echo "[clau:$TIER] Done."
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

  heavyRunner = mkRunnerScript { tier = "heavy"; maxWorkers = 2; serviceName = "worker"; };
  fastRunner = mkRunnerScript { tier = "fast"; maxWorkers = 1; serviceName = "worker-fast"; };
in {
  # ── Heavy worker (hourly) ────────────────────────────────────────
  systemd.services.claude-autonomous = {
    description = "Claudinho heavy task runner";
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
    description = "Run Claudinho heavy tasks every hour";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };

  # ── Fast worker (every 10 min) ───────────────────────────────────
  systemd.services.claude-autonomous-fast = {
    description = "Claudinho fast task runner";
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
    description = "Run Claudinho fast tasks every 10 minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/10";
      Persistent = true;
    };
  };

  # ── Reset service ────────────────────────────────────────────────
  systemd.services.claude-autonomous-reset = {
    description = "Reset stuck Claudinho tasks";
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
