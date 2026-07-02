{ pkgs, lib, ... }:

{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;

    # GC (autoPrune rootful + timer rootless) → modules/system/garbage.nix
  };

  # dockerSocket.enable liga SÓ o socket rootful de sistema. O coruja up,
  # lazydocker e os containers do dev-stack rodam ROOTLESS → dependem do
  # socket de usuário (/run/user/$UID/podman/podman.sock).
  #
  # Histórico: até ~16/06/2026 o nixpkgs NÃO expunha as user units rootless e a
  # gente declarava `systemd.user.{sockets,services}.podman` à mão. A partir do
  # bump de 17/06 o pacote podman (5.8.2) JÁ entrega as user units completas e
  # corretas em `share/systemd/user/` (podman.service: Type=exec, ExecStart=podman
  # system service, Requires=podman.socket; + podman.socket). Confirmado via
  # `systemctl --user cat podman.service`.
  #
  # Logo, NÃO redeclarar service/socket: como já existe uma base, qualquer
  # serviceConfig/socketConfig nosso vira DROP-IN ADITIVO sobre ela → 2º ExecStart
  # ("podman.service: ...more than one ExecStart= ... Refusing.") ou 2º ListenStream
  # ("Address already in use"). Só `wantedBy` é seguro: gera apenas [Install]
  # (symlink em sockets.target.wants/), sem colidir com o conteúdo do pacote.
  # Não usar systemd.packages = [ pkgs.podman ] (re-linka o podman-system-generator
  # que virtualisation.podman já instala → File exists no drv system-generators).
  systemd.user.sockets.podman.wantedBy = [ "sockets.target" ];

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
  # DOCKER_HOST aponta pro socket ROOTLESS do usuário. O formato correto é
  # `unix://` (esquema) + caminho ABSOLUTO → TRÊS barras: `unix:///run/...`.
  # XDG_RUNTIME_DIR já é absoluto (/run/user/$UID), então a 1ª branch dá 3 barras
  # naturalmente. A 2ª branch (fallback p/ contexto sem login, ex: systemd --user)
  # PRECISA da barra extra antes de `run` — senão vira `unix://run/...` (2 barras),
  # onde `run` é tratado como host e o caminho fica relativo → "Cannot connect".
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
    dtop # TUI dashboard multi-host (amir20) — fala com o socket via DOCKER_HOST
    dockmate # TUI gerenciador de container
  ];
}
