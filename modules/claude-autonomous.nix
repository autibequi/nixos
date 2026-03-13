{ pkgs, ... }:
let
  user = "pedrinho";
  projectDir = "/home/${user}/projects/nixos";
  compose = "${pkgs.docker-compose}/bin/docker-compose -f ${projectDir}/docker-compose.claude.yml";

  # Singleton: roda um único container worker que processa todas as tasks sequencialmente
  # O flock dentro do clau-runner.sh garante singleton mesmo se chamado manualmente em paralelo
  runnerScript = pkgs.writeShellScript "clau-dispatch" ''
    set -euo pipefail
    cd ${projectDir}

    # Verifica se já tem worker rodando (belt + suspenders com o flock interno)
    existing=$(docker ps --filter "label=com.docker.compose.service=worker" --format "{{.ID}}" 2>/dev/null | head -1)
    if [ -n "$existing" ]; then
      echo "[clau] Worker container já rodando ($existing). Singleton ativo — saindo."
      exit 0
    fi

    # Verifica se há tasks disponíveis antes de levantar container
    pending=$(ls -1 tasks/pending/ 2>/dev/null | grep -v '\.gitkeep' | head -1 || true)
    recurring=$(ls -1 tasks/recurring/ 2>/dev/null | grep -v '\.gitkeep' | head -1 || true)
    if [ -z "$pending" ] && [ -z "$recurring" ]; then
      echo "[clau] Sem tarefas disponíveis."
      exit 0
    fi

    echo "[clau] Iniciando worker singleton..."
    ${compose} run --rm -T worker /workspace/scripts/clau-runner.sh
  '';

  # Cleanup: devolve tasks órfãs de running/ pro lugar de origem
  cleanupScript = pkgs.writeShellScript "clau-cleanup" ''
    cd ${projectDir}

    # Para container worker se ainda estiver rodando
    ${compose} kill worker 2>/dev/null || true
    ${compose} rm -f worker 2>/dev/null || true

    # Devolve tasks órfãs em running/
    for dir in tasks/running/*/; do
      [ -d "$dir" ] || continue
      name=$(basename "$dir")
      source=$(grep '^source=' "$dir/.lock" 2>/dev/null | cut -d= -f2 || echo "pending")
      rm -f "$dir/.lock"
      if [ "$source" = "recurring" ]; then
        mv "$dir" "tasks/recurring/$name" 2>/dev/null || rm -rf "$dir"
        echo "[clau-cleanup] $name → recurring/"
      else
        mv "$dir" "tasks/pending/$name" 2>/dev/null || rm -rf "$dir"
        echo "[clau-cleanup] $name → pending/"
      fi
    done

    # Limpa lockfile
    rm -f .ephemeral/.clau.lock
  '';
in {
  systemd.services.claude-autonomous = {
    description = "Claudinho autonomous task runner (singleton)";
    after = [ "network-online.target" ];
    # Impede execução concorrente pelo próprio systemd
    conflicts = [ "claude-autonomous-reset.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = user;
      Group = "users";
      WorkingDirectory = projectDir;

      ExecStart = "${runnerScript}";

      # Cleanup automático em qualquer saída (sucesso, falha, timeout, kill)
      ExecStopPost = "${cleanupScript}";

      # Timeout generoso: max 20 tasks × 10min cada
      TimeoutStartSec = "3h";
      TimeoutStopSec = "2min";

      # Restart automático em falha (com backoff)
      Restart = "on-failure";
      RestartSec = "30s";
      # Não reinicia em loop infinito
      StartLimitIntervalSec = "10min";
      StartLimitBurst = 3;

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

  # Service dedicado pra reset manual: systemctl start claude-autonomous-reset
  systemd.services.claude-autonomous-reset = {
    description = "Reset stuck Claudinho tasks";
    conflicts = [ "claude-autonomous.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = user;
      Group = "users";
      WorkingDirectory = projectDir;
      ExecStart = "${cleanupScript}";
      Environment = [
        "HOME=/home/${user}"
        "XDG_RUNTIME_DIR=/run/user/1000"
        "DOCKER_HOST=unix:///run/podman/podman.sock"
        "WAYLAND_DISPLAY=wayland-1"
      ];
    };
  };
}
