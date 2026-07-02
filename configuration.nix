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

  # Cada pasta tem um default.nix que importa seus módulos ativos.
  # Para ligar/desligar um módulo, edite o default.nix da pasta correspondente.
  imports = [
    ./modules/boot # bootloader, kernel, plymouth, hibernate
    ./modules/hardware # drivers, firmware, áudio, periféricos
    ./modules/system # nix, locale, users, networking, performance, shell, pacotes
    ./modules/desktop # hyprland + greeter
    ./modules/services # daemons opt-in (ai, lmstudio, obsidian-sync, steam, virt)
    ./modules/apps # ambiente de trabalho (Estratégia)

    # ── Experiments (opt-in, controle individual aqui) ──
    ./modules/experiments/podman.nix # engine de containers (rootless + dockerCompat)
    ./modules/experiments/flatpak.nix
    # ./modules/experiments/dms.nix          # DankMaterialShell (também disponível via input dms no flake)
  ];
}
