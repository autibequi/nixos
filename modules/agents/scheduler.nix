# =============================================================================
# scheduler.nix — Puppy scheduler (long-running container)
# =============================================================================
# Single container runs 24/7; loop runs puppy-scheduler.sh every 10 min.
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
  composeBin = if isPodman then "${pkgs.podman-compose}/bin/podman-compose" else "${pkgs.docker-compose}/bin/docker-compose";
  composeFileMain = "${projectDir}/zion/cli/docker-compose.puppy.yml";
  composeFilePodman = if isPodman then " -f ${projectDir}/zion/cli/docker-compose.podman.yml" else "";
  composeProject = "puppy-workers";
  networkName = "nixos_default";

  commonEnv = [
    "HOME=/home/${user}"
    "XDG_RUNTIME_DIR=/run/user/1000"
    "WAYLAND_DISPLAY=wayland-1"
    "PATH=${enginePkg}/bin:${composePkg}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.bash}/bin:/run/current-system/sw/bin"
    "SCHEDULER_VAULT_DIR=${vaultDir}"
    "SCHEDULER_PROJECT_DIR=${projectDir}"
    "OBSIDIAN_PATH=${vaultDir}"
  ];

  cleanupScript = "${projectDir}/scripts/puppy-cleanup.sh";

  # Start script: ensure network, pick compose file path, run up -d scheduler. Exit 0 so activation never fails.
  startScript = pkgs.writeShellScript "claude-scheduler-container-start" ''
    set -e
    cd ${projectDir}
    export PATH="${enginePkg}/bin:${composePkg}/bin:$PATH"
    # Ensure external network exists (compose expects it)
    if ! ${enginePkg}/bin/${containers.engine} network inspect ${networkName} &>/dev/null; then
      echo "[claude-scheduler-container] Creating network ${networkName}..."
      ${enginePkg}/bin/${containers.engine} network create ${networkName} 2>/dev/null || true
    fi
    COMPOSE_FILES=""
    if [ -f "${composeFileMain}" ]; then
      COMPOSE_FILES="-f ${composeFileMain}${composeFilePodman}"
    else
      echo "[puppy-scheduler-container] No compose file at zion/cli/docker-compose.puppy.yml" >&2
      exit 0
    fi
    if ${composeBin} $COMPOSE_FILES -p ${composeProject} up -d scheduler 2>&1; then
      echo "[puppy-scheduler-container] Scheduler started."
    else
      echo "[puppy-scheduler-container] compose up failed (check journalctl)." >&2
    fi
    exit 0
  '';

  stopScript = pkgs.writeShellScript "claude-scheduler-container-stop" ''
    set -e
    cd ${projectDir}
    export PATH="${enginePkg}/bin:${composePkg}/bin:$PATH"
    [ -f "${composeFileMain}" ] || exit 0
    COMPOSE_FILES="-f ${composeFileMain}"
    podman_yml="''${composeFileMain%.claude.yml}.podman.yml"
    [ -f "$podman_yml" ] && COMPOSE_FILES="$COMPOSE_FILES -f $podman_yml"
    ${composeBin} $COMPOSE_FILES -p ${composeProject} stop scheduler 2>/dev/null || true
  '';

  containerEngineService = if isPodman then "podman.service" else "docker.socket";
in {
  config = {
    # ─────────────────────────────────────────────────────────────────────────
    # Puppy scheduler container (long-running; tick every 10 min inside)
    # ─────────────────────────────────────────────────────────────────────────
    systemd.services.claude-scheduler-container = {
      description = "Puppy scheduler container (tick every 10 min)";
      after = [ "network-online.target" containerEngineService ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = user;
        Group = "users";
        WorkingDirectory = projectDir;
        ExecStart = "${startScript}";
        ExecStop = "${stopScript}";
        Environment = commonEnv;
      };
    };

    # ─────────────────────────────────────────────────────────────────────────
    # Reset stuck Puppy tasks and restart scheduler container
    # ─────────────────────────────────────────────────────────────────────────
    systemd.services.claude-scheduler-reset = {
      description = "Reset stuck Puppy tasks and restart scheduler";
      serviceConfig = {
        Type = "oneshot";
        User = user;
        Group = "users";
        WorkingDirectory = projectDir;
        ExecStart = pkgs.writeShellScript "puppy-scheduler-reset" ''
          set -euo pipefail
          cd ${projectDir}
          export PATH="${enginePkg}/bin:${composePkg}/bin:$PATH"
          echo "[reset] Stopping scheduler container..."
          ${stopScript} 2>/dev/null || true
          echo "[reset] Running cleanup..."
          export SCHEDULER_VAULT_DIR="${vaultDir}"
          export SCHEDULER_PROJECT_DIR="${projectDir}"
          ${pkgs.bash}/bin/bash ${cleanupScript}
          echo "[reset] Starting scheduler container..."
          ${startScript}
        '';
        Environment = commonEnv;
      };
    };
  };
}
