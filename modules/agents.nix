# =============================================================================
# agents.nix — Agentes no host (Zion, Puppy workers, Claude Ask, timers)
# =============================================================================

{ config, lib, pkgs, ... }:
let
  containers = config.local.containers;
  isPodman = containers.engine == "podman";

  user = "pedrinho";
  projectDir = "/home/${user}/nixos";
  vaultDir = "/home/${user}/.oobsidian/Work";

  enginePkg = if isPodman then pkgs.podman else pkgs.docker;
  composePkg = if isPodman then pkgs.podman-compose else pkgs.docker-compose;
  composeBin = if isPodman then "podman-compose" else "docker-compose";
  composeFiles = "-f ${projectDir}/zion/cli/docker-compose.claude.yml"
    + (if isPodman then " -f ${projectDir}/zion/cli/docker-compose.podman.yml" else "");
  compose = "${composePkg}/bin/${composeBin} ${composeFiles} -p puppy-workers";

  hostSocket = if isPodman then "/run/podman/podman.sock" else "/var/run/docker.sock";
  userSocket = if isPodman then "unix:///run/user/1000/podman/podman.sock" else "unix:///var/run/docker.sock";

  logsDir = "${projectDir}/.ephemeral/logs";
  dispatchLockDir = "${projectDir}/.ephemeral/locks";

  cfgClaudinho = config.local.agents.claudinho or { };
  maxConcurrentWorkers = cfgClaudinho.maxConcurrentWorkers or 1;
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

  # Multi-worker dispatch — controle de custo: maxConcurrentWorkers no sistema, maxWorkers por clock (fast/heavy/slow)
  mkRunnerScript = { clock, maxWorkers, serviceName }: pkgs.writeShellScript "puppy-dispatch-${clock}" ''
    set -euo pipefail
    cd ${projectDir}

    MAX_WORKERS=${toString maxWorkers}
    MAX_CONCURRENT=${toString maxConcurrentWorkers}
    CLOCK="${clock}"
    LOGFILE="${logsDir}/worker-${clock}.log"
    GLOBAL_LOCK="${dispatchLockDir}/puppy-single.lock"

    mkdir -p "${logsDir}" "${dispatchLockDir}"

    # maxConcurrentWorkers=1: só um runner por vez (lock durante toda a execução)
    if [ "$MAX_CONCURRENT" -eq 1 ]; then
      exec 199>"$GLOBAL_LOCK"
      if ! ${pkgs.util-linux}/bin/flock -n 199; then
        echo "[puppy:$CLOCK] Outro worker em execução (maxConcurrent=1) — skip."
        exit 0
      fi
    fi

    # Rotate log if > 500KB
    if [ -f "$LOGFILE" ] && [ "$(stat -c%s "$LOGFILE" 2>/dev/null || echo 0)" -gt 512000 ]; then
      tail -200 "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
    fi

    # Redirect all output to log file (and stdout for journal)
    exec > >(${pkgs.coreutils}/bin/tee -a "$LOGFILE") 2>&1

    if [ ! -f ${vaultDir}/kanban.md ] && [ ! -f ${vaultDir}/scheduled.md ]; then
      echo "[puppy:$CLOCK] kanban.md/scheduled.md não encontrados."
      exit 0
    fi

    kanban_cards=$(grep -c '^\- \[' ${vaultDir}/kanban.md 2>/dev/null || echo "0")
    scheduled_cards=$(grep -c '^\- \[' ${vaultDir}/scheduled.md 2>/dev/null || echo "0")
    total=$((kanban_cards + scheduled_cards))
    if [ "$total" -eq 0 ]; then
      echo "[puppy:$CLOCK] Sem cards no kanban/scheduled."
      exit 0
    fi

    SERVICE=$( [ "$CLOCK" = "every10" ] && echo "worker-fast" || echo "worker" )

    # Ensure container network exists (compose needs it)
    COMPOSE_PROJECT="puppy-workers"
    NETWORK="puppy-workers_default"
    if ! ${enginePkg}/bin/${containers.engine} network exists "$NETWORK" 2>/dev/null; then
      echo "[puppy:$CLOCK] Criando network $NETWORK..."
      ${enginePkg}/bin/${containers.engine} network create "$NETWORK" 2>/dev/null || true
    fi

    _count_running() {
      ${enginePkg}/bin/${containers.engine} ps -q --filter "label=puppy.worker.id" 2>/dev/null | wc -l
    }

    PIDS=()
    for i in $(seq 1 $MAX_WORKERS); do
      WORKER_ID="$CLOCK-$i"

      existing=$(${enginePkg}/bin/${containers.engine} ps --filter "label=com.docker.compose.service=$SERVICE" \
        --filter "label=puppy.worker.id=$WORKER_ID" \
        --format "{{.ID}}" 2>/dev/null | head -1)
      if [ -n "$existing" ]; then
        echo "[puppy] $WORKER_ID já rodando ($existing) — skip"
        continue
      fi

      # Respeitar limite global (quando >1 runner pode rodar em paralelo)
      if [ "$MAX_CONCURRENT" -gt 1 ]; then
        exec 199>"$GLOBAL_LOCK"
        ${pkgs.util-linux}/bin/flock 199
        running=$(_count_running)
        if [ "$running" -ge "$MAX_CONCURRENT" ]; then
          exec 199>&-
          echo "[puppy:$CLOCK] Limite global atingido ($running >= $MAX_CONCURRENT) — skip launch"
          break
        fi
      fi

      echo "[puppy] Lançando $WORKER_ID ($CLOCK)..."
      ${compose} run --rm -T \
        -e SCHEDULER_WORKER_ID="$WORKER_ID" \
        -e SCHEDULER_CLOCK="$CLOCK" \
        -l puppy.worker.id="$WORKER_ID" \
        $SERVICE /zion/scripts/puppy-runner.sh &
      PIDS+=($!)
      [ "$MAX_CONCURRENT" -gt 1 ] && exec 199>&-
    done

    if [ ''${#PIDS[@]} -eq 0 ]; then
      echo "[puppy:$CLOCK] Nenhum worker lançado."
      exit 0
    fi

    echo "[puppy:$CLOCK] ''${#PIDS[@]} workers lançados."
    for pid in "''${PIDS[@]}"; do
      wait "$pid" 2>/dev/null || true
    done
    echo "[puppy:$CLOCK] Done."
  '';

  cleanupScript = pkgs.writeShellScript "puppy-cleanup" ''
    cd ${projectDir}
    for dir in obsidian/_agent/tasks/running/*/; do
      [ -d "$dir" ] || continue
      name=$(basename "$dir")
      source=$(grep '^source=' "$dir/.lock" 2>/dev/null | cut -d= -f2 || echo "pending")
      rm -f "$dir/.lock"
      if [ "$source" = "recurring" ]; then
        rm -rf "$dir"
        echo "[cleanup] $name (recurring) removed"
      else
        mv "$dir" "obsidian/_agent/tasks/pending/$name" 2>/dev/null || rm -rf "$dir"
        echo "[cleanup] $name → pending/"
      fi
    done
    rm -f .ephemeral/.kanban.lock .ephemeral/locks/*.lock
  '';

  heavyRunner = mkRunnerScript { clock = "every60"; maxWorkers = maxWorkersHeavy; serviceName = "worker"; };
  fastRunner = mkRunnerScript { clock = "every10"; maxWorkers = maxWorkersFast; serviceName = "worker-fast"; };

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
        claudinho = lib.mkOption {
          type = lib.types.submodule {
            options = {
              maxConcurrentWorkers = lib.mkOption {
                type = lib.types.ints.positive;
                default = 1;
                description = "Máximo de containers worker (Claude) rodando ao mesmo tempo no sistema. Controle de custo; 1 = só um por vez.";
              };
              maxWorkersFast = lib.mkOption {
                type = lib.types.ints.positive;
                default = 1;
                description = "Máximo de workers que o timer every10 (fast) pode levantar por execução.";
              };
              maxWorkersHeavy = lib.mkOption {
                type = lib.types.ints.positive;
                default = 1;
                description = "Máximo de workers que o timer every60 (heavy) pode levantar por execução.";
              };
              maxWorkersSlow = lib.mkOption {
                type = lib.types.ints.positive;
                default = 1;
                description = "Máximo de workers que o timer every240 (slow) pode levantar por execução.";
              };
            };
          };
          default = { };
          description = "Controle de workers CLAUDINHO (custos; fast/heavy/slow).";
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
      ExecStart = pkgs.writeShellScript "puppy-hard-reset" ''
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
