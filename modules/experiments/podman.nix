{ pkgs, lib, ... }:

{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # dockerSocket.enable liga SÓ o socket rootful de sistema. O coruja up,
  # lazydocker e os containers do dev-stack rodam ROOTLESS → dependem do
  # socket de usuário (/run/user/$UID/podman/podman.sock), que o nixpkgs
  # não expõe (não há rootlessSocket.enable). O pacote podman já traz a
  # unit podman.socket; systemd.packages a torna visível ao systemctl --user
  # e wantedBy liga o socket no boot da sessão do usuário.
  systemd.packages = [ pkgs.podman ];
  systemd.user.sockets.podman.wantedBy = [ "sockets.target" ];

  virtualisation.containers.containersConf.settings.engine.runtime = "crun";

  # Kernel 6.18+ suporta overlay idmap nativo — evita cópia de ~1.6 GB
  # no primeiro arranque rootless. fuse-overlayfs não suporta idmap.
  virtualisation.containers.storage.settings.storage.options.overlay.mount_program =
    lib.mkForce "";

  # Lazydocker / ferramentas tipo Docker → API do Podman *rootless* (socket do seu usuário).
  # Evita "permission denied" em /run/podman/podman.sock (grupo `podman` + socket de sistema).
  # extraInit cobre TODOS os shells de login (bash/sh/zsh) — não precisa duplicar em programs.zsh.shellInit.
  environment.extraInit = ''
    if [ -n "''${XDG_RUNTIME_DIR:-}" ]; then
      export DOCKER_HOST="unix://''${XDG_RUNTIME_DIR}/podman/podman.sock"
    elif [ -n "''${UID:-}" ]; then
      export DOCKER_HOST="unix:///run/user/''${UID}/podman/podman.sock"
    fi
  '';

  environment.systemPackages = with pkgs; [
    crun
    podman-compose
    lazydocker
    dive
  ];
}
