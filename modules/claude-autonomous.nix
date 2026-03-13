{ pkgs, ... }:
let
  user = "pedrinho";
  projectDir = "/home/${user}/projects/nixos";
  compose = "${pkgs.docker-compose}/bin/docker-compose -f ${projectDir}/docker-compose.claude.yml";

  # Script que spawna um worker por task disponível
  runnerScript = pkgs.writeShellScript "clau-dispatch" ''
    set -euo pipefail
    cd ${projectDir}

    pending=$(ls -1 tasks/pending/ 2>/dev/null | grep -v '\.gitkeep' || true)
    recurring=$(ls -1 tasks/recurring/ 2>/dev/null | grep -v '\.gitkeep' || true)
    all="$pending $recurring"
    count=0

    for task in $all; do
      [ -z "$task" ] && continue
      [ -d "tasks/running/$task" ] && continue
      [ ! -f "tasks/pending/$task/CLAUDE.md" ] && [ ! -f "tasks/recurring/$task/CLAUDE.md" ] && continue
      echo "[clau] Spawning worker: $task"
      ${compose} run --rm -d -T worker /workspace/scripts/clau-runner.sh 300 "$task" &
      count=$((count + 1))
    done
    wait

    [ "$count" -eq 0 ] && echo "[clau] Sem tarefas disponíveis." || echo "[clau] $count workers spawned."
  '';

  # Cleanup: devolve tasks órfãs de running/ pro lugar de origem
  cleanupScript = pkgs.writeShellScript "clau-cleanup" ''
    cd ${projectDir}

    # Mata containers worker que ainda estejam rodando
    ${compose} kill worker 2>/dev/null || true
    ${compose} rm -f worker 2>/dev/null || true

    for dir in tasks/running/*/; do
      [ -d "$dir" ] || continue
      name=$(basename "$dir")
      source=$(grep '^source=' "$dir/.lock" 2>/dev/null | cut -d= -f2 || echo "pending")
      rm -f "$dir/.lock"
      if [ "$source" = "recurring" ]; then
        mv "$dir" "tasks/recurring/$name"
        echo "[clau-cleanup] $name → recurring/"
      else
        mv "$dir" "tasks/pending/$name"
        echo "[clau-cleanup] $name → pending/"
      fi
    done
  '';
in {
  systemd.services.claude-autonomous = {
    description = "Claudinho autonomous task runner";
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = user;
      WorkingDirectory = projectDir;
      ExecStart = "${runnerScript}";
      ExecStopPost = "${cleanupScript}";
      TimeoutStartSec = "10min";
      TimeoutStopSec = "2min";
      Environment = [
        "HOME=/home/${user}"
        "XDG_RUNTIME_DIR=/run/user/1000"
        "DOCKER_HOST=unix:///run/podman/podman.sock"
        "WAYLAND_DISPLAY=wayland-1"
      ];
    };
  };

  systemd.timers.claude-autonomous = {
    description = "Run Claudinho tasks every hour";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      RandomizedDelaySec = "5min";
      Persistent = true;
    };
  };
}
