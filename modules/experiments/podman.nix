{ pkgs, lib, ... }:

{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  virtualisation.containers.containersConf.settings.engine.runtime = "crun";

  # Kernel 6.18+ suporta overlay idmap nativo — evita cópia de ~1.6 GB
  # no primeiro arranque rootless. fuse-overlayfs não suporta idmap.
  virtualisation.containers.storage.settings.storage.options.overlay.mount_program =
    lib.mkForce "";

  # Lazydocker / ferramentas tipo Docker → API do Podman *rootless* (socket do seu usuário).
  # Evita "permission denied" em /run/podman/podman.sock (grupo `podman` + socket de sistema).
  environment.extraInit = ''
    if [ -n "''${XDG_RUNTIME_DIR:-}" ]; then
      export DOCKER_HOST="unix://''${XDG_RUNTIME_DIR}/podman/podman.sock"
    elif [ -n "''${UID:-}" ]; then
      export DOCKER_HOST="unix:///run/user/''${UID}/podman/podman.sock"
    fi
  '';

  programs.zsh.shellInit = lib.mkAfter ''
    if [ -n "''${XDG_RUNTIME_DIR:-}" ]; then
      export DOCKER_HOST="unix://''${XDG_RUNTIME_DIR}/podman/podman.sock"
    else
      export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
    fi
  '';

  environment.systemPackages = with pkgs; [
    crun
    podman-compose
    lazydocker
    dive
  ];
}
