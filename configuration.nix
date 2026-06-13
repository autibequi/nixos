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
    ./modules/hardware/gpu-toggle.nix # wrapper runtime gpu-offload + comando gpu-profile (home/mobile/auto)
    ./modules/hardware/ddc.nix # ddcutil + i2c-dev para brilho via DDC/CI

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
    ./modules/core/greetd.nix # greeter: tuigreet via greetd
    ./modules/core/hyprland
    ./modules/core/obsidian-sync.nix
    ./modules/core/work.nix
    # ./modules/core/home.nix # home-manager (NÃO ativo: input ausente no flake.nix). psd migrou p/ services/ramsync.nix; só resta o tailscale-systray aqui

    # ── Services ───────────────────────────────────────
    ./modules/services/ai.nix
    ./modules/services/lmstudio.nix # serviço opt-in (services.lmstudio.enable; default false em services.nix)
    ./modules/services/ramsync.nix # profile-em-RAM (psd: browsers em tmpfs)
    ./modules/services/steam.nix
    ./modules/services/virt.nix

    # ── Experiments ────────────────────────────────────
    # ./modules/experiments/dms.nix          # DankMaterialShell (também disponível via input dms no flake)
    # ./modules/experiments/whisper-ptt.nix  # on-demand: PTT
    ./modules/experiments/flatpak.nix
    ./modules/experiments/podman.nix # engine de containers ativo (rootless + dockerCompat)

  ];
}
