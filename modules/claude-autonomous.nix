{ pkgs, ... }:
let
  user = "pedrinho";
  projectDir = "/home/${user}/nixos";
  vaultDir = "/home/${user}/.ovault/Work";
  compose = "${pkgs.podman-compose}/bin/podman-compose -f ${projectDir}/docker-compose.claude.yml";

  # Multi-worker dispatch: lança N workers em paralelo, cada um sequencial
  runnerScript = pkgs.writeShellScript "clau-dispatch" ''
    set -euo pipefail
    cd ${projectDir}

    MAX_WORKERS=''${CLAU_MAX_WORKERS:-2}

    # Verifica se há tasks disponíveis (via kanban)
    if [ ! -f ${vaultDir}/kanban.md ]; then
      echo "[clau] kanban.md não encontrado em ${vaultDir}."
      exit 0
    fi

    # Checar se há algo no Backlog ou Recorrentes
    backlog=$(grep -c '^\- \[' ${vaultDir}/kanban.md 2>/dev/null || echo "0")
    if [ "$backlog" -eq 0 ]; then
      echo "[clau] Sem cards no kanban."
      exit 0
    fi

    PIDS=()
    for i in $(seq 1 $MAX_WORKERS); do
      WORKER_ID="worker-$i"

      # Checar se worker-$i já roda
      existing=$(${pkgs.podman}/bin/podman ps --filter "label=com.docker.compose.service=worker" \
        --filter "label=clau.worker.id=$WORKER_ID" \
        --format "{{.ID}}" 2>/dev/null | head -1)
      if [ -n "$existing" ]; then
        echo "[clau] $WORKER_ID já rodando ($existing) — skip"
        continue
      fi

      echo "[clau] Lançando $WORKER_ID..."
      ${compose} run --rm -T \
        -e CLAU_WORKER_ID="$WORKER_ID" \
        -l clau.worker.id="$WORKER_ID" \
        worker /workspace/scripts/clau-runner.sh &
      PIDS+=($!)
    done

    if [ ''${#PIDS[@]} -eq 0 ]; then
      echo "[clau] Nenhum worker lançado."
      exit 0
    fi

    echo "[clau] ''${#PIDS[@]} workers lançados. Aguardando..."
    for pid in "''${PIDS[@]}"; do
      wait "$pid" 2>/dev/null || true
    done
    echo "[clau] Todos os workers finalizaram."
  '';

  # Cleanup: devolve tasks órfãs de running/ pro lugar de origem
  cleanupScript = pkgs.writeShellScript "clau-cleanup" ''
    cd ${projectDir}

    for dir in vault/_agent/tasks/running/*/; do
      [ -d "$dir" ] || continue
      name=$(basename "$dir")
      source=$(grep '^source=' "$dir/.lock" 2>/dev/null | cut -d= -f2 || echo "pending")
      rm -f "$dir/.lock"
      if [ "$source" = "recurring" ]; then
        rm -rf "$dir"
        echo "[clau-cleanup] $name (recurring copy) removed"
      else
        mv "$dir" "vault/_agent/tasks/pending/$name" 2>/dev/null || rm -rf "$dir"
        echo "[clau-cleanup] $name → pending/"
      fi
    done

    # Limpa lockfiles
    rm -f .ephemeral/.kanban.lock
    rm -f .ephemeral/locks/*.lock
  '';
in {
  systemd.services.claude-autonomous = {
    description = "Claudinho autonomous task runner (multi-worker)";
    after = [ "network-online.target" ];
    conflicts = [ "claude-autonomous-reset.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = user;
      Group = "users";
      WorkingDirectory = projectDir;

      ExecStart = "${runnerScript}";
      ExecStopPost = "${cleanupScript}";

      # 2 workers × tasks (~20min each) + margem
      TimeoutStartSec = "45min";
      TimeoutStopSec = "2min";

      Restart = "no";

      Environment = [
        "HOME=/home/${user}"
        "XDG_RUNTIME_DIR=/run/user/1000"
        "DOCKER_HOST=unix:///run/podman/podman.sock"
        "WAYLAND_DISPLAY=wayland-1"
        "CLAU_MAX_WORKERS=2"
        "PATH=${pkgs.podman}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.bash}/bin:/run/current-system/sw/bin"
      ];
    };
  };

  systemd.timers.claude-autonomous = {
    description = "Run Claudinho tasks every hour";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };

  systemd.services.claude-autonomous-reset = {
    description = "Reset stuck Claudinho tasks (kills workers)";
    conflicts = [ "claude-autonomous.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = user;
      Group = "users";
      WorkingDirectory = projectDir;
      ExecStart = pkgs.writeShellScript "clau-hard-reset" ''
        cd ${projectDir}
        echo "[clau-reset] Parando workers..."
        ${compose} kill worker 2>/dev/null || true
        ${compose} rm -f worker 2>/dev/null || true
        ${cleanupScript}
      '';
      Environment = [
        "HOME=/home/${user}"
        "XDG_RUNTIME_DIR=/run/user/1000"
        "DOCKER_HOST=unix:///run/podman/podman.sock"
        "WAYLAND_DISPLAY=wayland-1"
        "PATH=${pkgs.podman}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.bash}/bin:/run/current-system/sw/bin"
      ];
    };
  };
}
