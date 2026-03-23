{
  ...
}:
{
  imports = [

    # ── Hardware ───────────────────────────────────────
    ./hardware.nix
    ./modules/hardware/asus.nix
    ./modules/hardware/nvidia.nix

    # ── Core ───────────────────────────────────────────
    ./modules/core/nix.nix
    ./modules/core/core.nix
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
    ./modules/core/greetd.nix
    ./modules/core/hyprland.nix
    ./modules/core/obsidian-sync.nix
    ./modules/core/leech-tick.nix
    ./modules/core/work.nix

    # ── Services ───────────────────────────────────────
    ./modules/services/ai.nix
    ./modules/services/containers.nix
    ./modules/services/lmstudio.nix
    ./modules/services/netdata.nix
    ./modules/services/steam.nix
    ./modules/services/virt.nix

    # ── Experiments ────────────────────────────────────
    # ./modules/experiments/whisper-ptt.nix  # on-demand: PTT
    # ./modules/experiments/bongocat.nix     # fun mas desnecessário
    # ./modules/experiments/tlp.nix
    # ./modules/experiments/flatpak.nix
    # ./modules/experiments/cosmic.nix
    # ./modules/experiments/kde.nix
    # ./modules/experiments/openclaw.nix
    # ./modules/experiments/docker.nix       # use containers.nix
    # ./modules/experiments/podman.nix       # use containers.nix
    # ./modules/experiments/gnome/core.nix

  ];
}
