# =============================================================================
# scheduler.nix — CLAUDINHO scheduler as a long-running container
# =============================================================================
# Single container runs 24/7; inside it a loop runs clau-scheduler.sh every
# 10 min (tick + runner in-process). No systemd timer on the host.
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
  # Try claudinho/ first (agents.nix layout / symlink), then claudinho/claudio-cli/
  composeFileMain = "${projectDir}/claudinho/docker-compose.claude.yml";
  composeFileAlt = "${projectDir}/claudinho/claudio-cli/docker-compose.claude.yml";
  composeFilePodman = if isPodman then " -f ${projectDir}/claudinho/docker-compose.podman.yml" else "";
  composeFilePodmanAlt = if isPodman then " -f ${projectDir}/claudinho/claudio-cli/docker-compose.podman.yml" else "";
  composeProject = "clau-workers";
  networkName = "nixos_default";

  commonEnv = [
    "HOME=/home/${user}"
    "XDG_RUNTIME_DIR=/run/user/1000"
    "WAYLAND_DISPLAY=wayland-1"
    "PATH=${enginePkg}/bin:${composePkg}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.bash}/bin:/run/current-system/sw/bin"
    "CLAU_VAULT_DIR=${vaultDir}"
    "CLAU_PROJECT_DIR=${projectDir}"
    "OBSIDIAN_PATH=${vaultDir}"
  ];

  cleanupScript = "${projectDir}/scripts/clau-cleanup.sh";

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
    elif [ -f "${composeFileAlt}" ]; then
      COMPOSE_FILES="-f ${composeFileAlt}${composeFilePodmanAlt}"
    else
      echo "[claude-scheduler-container] No compose file found at claudinho/docker-compose.claude.yml or claudinho/claudio-cli/docker-compose.claude.yml" >&2
      exit 0
    fi
    if ${composeBin} $COMPOSE_FILES -p ${composeProject} up -d scheduler 2>&1; then
      echo "[claude-scheduler-container] Scheduler container started."
    else
      echo "[claude-scheduler-container] compose up failed (check journalctl). Container may start after docker/podman is ready." >&2
    fi
    exit 0
  '';

  stopScript = pkgs.writeShellScript "claude-scheduler-container-stop" ''
    set -e
    cd ${projectDir}
    export PATH="${enginePkg}/bin:${composePkg}/bin:$PATH"
    for f in "${composeFileMain}" "${composeFileAlt}"; do
      [ -f "$f" ] || continue
      COMPOSE_FILES="-f $f"
      podman_yml="''${f%.claude.yml}.podman.yml"
      [ -f "$podman_yml" ] && COMPOSE_FILES="$COMPOSE_FILES -f $podman_yml"
      ${composeBin} $COMPOSE_FILES -p ${composeProject} stop scheduler 2>/dev/null || true
      break
    done
  '';

  containerEngineService = if isPodman then "podman.service" else "docker.socket";
in {
  config = {
    # ─────────────────────────────────────────────────────────────────────────
    # CLAUDINHO — Scheduler container (long-running; tick every 10 min inside)
    # ─────────────────────────────────────────────────────────────────────────
    systemd.services.claude-scheduler-container = {
      description = "CLAUDINHO scheduler container (tick every 10 min in-container)";
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
    # CLAUDINHO — Reset (stuck tasks): stop scheduler, cleanup, restart scheduler
    # ─────────────────────────────────────────────────────────────────────────
    systemd.services.claude-scheduler-reset = {
      description = "Reset stuck CLAUDINHO tasks and restart scheduler container";
      serviceConfig = {
        Type = "oneshot";
        User = user;
        Group = "users";
        WorkingDirectory = projectDir;
        ExecStart = pkgs.writeShellScript "clau-scheduler-reset" ''
          set -euo pipefail
          cd ${projectDir}
          export PATH="${enginePkg}/bin:${composePkg}/bin:$PATH"
          echo "[reset] Stopping scheduler container..."
          ${stopScript} 2>/dev/null || true
          echo "[reset] Running cleanup..."
          export CLAU_VAULT_DIR="${vaultDir}"
          export CLAU_PROJECT_DIR="${projectDir}"
          ${pkgs.bash}/bin/bash ${cleanupScript}
          echo "[reset] Starting scheduler container..."
          ${startScript}
        '';
        Environment = commonEnv;
      };
    };
  };
}
