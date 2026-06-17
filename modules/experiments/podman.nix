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
  # não expõe (não há rootlessSocket.enable). Declaramos o socket+service
  # de usuário à mão — NÃO via systemd.packages = [ pkgs.podman ], pois isso
  # re-linka o podman-system-generator que virtualisation.podman já instala
  # → colisão de symlink em system-generators (File exists).
  systemd.user.sockets.podman = {
    wantedBy = [ "sockets.target" ];
    socketConfig = {
      ListenStream = "%t/podman/podman.sock";
      SocketMode = "0660";
    };
  };
  systemd.user.services.podman = {
    unitConfig.Description = "Podman API Service (rootless)";
    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkgs.podman}/bin/podman system service --time=0";
      Restart = "on-failure";
    };
  };

  virtualisation.containers.containersConf.settings.engine.runtime = "crun";

  # Rootless: mount_program = fuse-overlayfs (OBRIGATÓRIO pra testcontainer).
  # O overlay NATIVO rootless (mount_program = "") quebra o copy-up de volume
  # anônimo (VOLUME da imagem): o copier subprocess falha com
  #   `chdir <vol>/_data: no such file or directory`
  # derrubando todo container com VOLUME (postgres/localstack do testcontainer)
  # e o `make test-ldi` inteiro. fuse-overlayfs faz o copy-up corretamente.
  # Trade-off: ~1.6 GB de cópia no primeiro arranque rootless — aceitável
  # frente a ter testcontainers funcionando. (idmap nativo não compensa quebrar
  # a suíte de testes de integração.)
  virtualisation.containers.storage.settings.storage.options.overlay.mount_program =
    lib.mkForce "${pkgs.fuse-overlayfs}/bin/fuse-overlayfs";

  # Lazydocker / ferramentas tipo Docker → API do Podman *rootless* (socket do seu usuário).
  # Evita "permission denied" em /run/podman/podman.sock (grupo `podman` + socket de sistema).
  # extraInit cobre TODOS os shells de login (bash/sh/zsh) — não precisa duplicar em programs.zsh.shellInit.
  environment.extraInit = ''
    if [ -n "''${XDG_RUNTIME_DIR:-}" ]; then
      export DOCKER_HOST="unix://''${XDG_RUNTIME_DIR}/podman/podman.sock"
    elif [ -n "''${UID:-}" ]; then
      export DOCKER_HOST="unix://run/user/''${UID}/podman/podman.sock"
    fi
  '';

  environment.systemPackages = with pkgs; [
    crun
    podman-compose
    lazydocker
    dive
  ];
}
