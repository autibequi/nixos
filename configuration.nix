{
  ...
}:
{
  config = {
    # ── Hardware mounts & boot ─────────────────────────
    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/1F53-9115";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
        "x-systemd.device-timeout=5s"
      ];
    };

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/ee52cc58-f10d-4979-8244-4386302649c5";
      fsType = "ext4"; # TODO: testar zfs com lz4 no proximo setup
      neededForBoot = true;
      options = [
        "defaults"
        "noatime"
      ];
    };

    boot.resumeDevice = "/dev/disk/by-uuid/17e5c565-c90c-4233-92c6-bb86adfed306";
    swapDevices = [ { device = "/dev/disk/by-uuid/17e5c565-c90c-4233-92c6-bb86adfed306"; } ];
  };

  imports = [

    # ── Hardware ───────────────────────────────────────
    ./modules/hardware/asus.nix
    ./modules/hardware/nvidia.nix
    ./modules/hardware/gpu-apps.nix # força apps GUI na dGPU (lista interna)

    # ── Core ───────────────────────────────────────────
    ./modules/core/nix.nix
    ./modules/core/core.nix
    ./modules/core/limine.nix
    ./modules/core/kernel.nix
    ./modules/core/shell.nix
    ./modules/core/fonts.nix
    ./modules/core/programs.nix
    ./modules/core/services.nix
    ./modules/core/packages.nix
    ./modules/core/hibernate.nix
    ./modules/core/bluetooth.nix
    ./modules/core/logiops.nix
    ./modules/core/plymouth.nix
    ./modules/core/greetd.nix # tuigreet via greetd — rollback se Ly falhar
    # ./modules/core/ly.nix          # Ly greeter (TUI)
    # ./modules/core/regreet.nix     # regreet (GTK4)
    ./modules/core/hyprland.nix
    ./modules/core/obsidian-sync.nix
    # ./modules/core/leech-tick.nix  # desabilitado: vennon não está mais em uso
    ./modules/core/work.nix
    # ./modules/core/home.nix

    # ── Services ───────────────────────────────────────
    ./modules/services/ai.nix
    # ./modules/services/containers.nix
    ./modules/services/lmstudio.nix
    # ./modules/services/netdata.nix  # desabilitado: usa stack OTEL (grafana/victoriametrics)
    ./modules/services/steam.nix
    ./modules/services/virt.nix

    # ── Experiments ────────────────────────────────────
    # ./modules/experiments/dms.nix
    # ./modules/experiments/whisper-ptt.nix  # on-demand: PTT
    # ./modules/experiments/bongocat.nix     # fun mas desnecessário
    # ./modules/experiments/tlp.nix
    # ./modules/experiments/flatpak.nix
    # ./modules/experiments/cosmic.nix
    # ./modules/experiments/kde.nix
    # ./modules/experiments/openclaw.nix
    # ./modules/experiments/docker.nix       # use containers.nix
    ./modules/experiments/podman.nix # use containers.nix
    # ./modules/experiments/gnome/core.nix

  ];
}
