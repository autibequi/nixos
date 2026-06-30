# ════════════════════════════════════════════════════════════════════
# modules/system/garbage.nix
#
# Ponto único de HOUSEKEEPING de disco — tudo que apaga lixo periódico:
#   • Nix store    → nix.gc (GC diário) + nix.optimise (dedup de hardlinks)
#   • NVMe         → fstrim semanal
#   • Containers   → prune Podman rootful (autoPrune) + rootless (timer user)
#   • ~/Downloads  → downloads-cleanup.nix (script dedicado, importado abaixo)
#
# Config INTRÍNSECA dos componentes fica no módulo deles (ex: o resto do
# Podman em experiments/podman.nix; settings do Nix em nix.nix). Aqui só o
# que é coleta de lixo agendada.
# ════════════════════════════════════════════════════════════════════
{ pkgs, ... }:
{
  imports = [
    ../services/downloads-cleanup.nix # screenshots +7d, Downloads → Pictures / Documents/missplaced
  ];

  # ── Nix store ────────────────────────────────────────────────────────────
  nix.gc = {
    automatic = true;
    dates = "daily"; # store inchava entre runs weekly (CachyOS + caches CUDA crescem rápido) → disco a 90%
    options = "--delete-older-than 3d"; # 3d mantém rollback recente sem acumular
    randomizedDelaySec = "30min"; # não brigar com autoUpgrade (Sun 03:00)
  };

  # Recupera espaço de hardlinks que o auto-optimise-store (nix.nix) perde ao
  # longo do tempo — paths novos só são deduplicados no build; o sweep pega o resto.
  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  # GC sob pressão DURANTE o build: quando o disco cai abaixo de min-free, o
  # nix-daemon libera store no meio da operação até atingir max-free. Rede de
  # segurança que o nix.gc (agendado) não dá — evita "no space left" num rebuild
  # grande com o disco já a 90%.
  nix.settings = {
    min-free = 5 * 1024 * 1024 * 1024; # 5 GiB: gatilho do GC durante build
    max-free = 20 * 1024 * 1024 * 1024; # 20 GiB: para de coletar ao liberar isso
  };

  # ── NVMe ─────────────────────────────────────────────────────────────────
  # TRIM periódico para saúde do NVMe interno.
  services.fstrim.enable = true;
  services.fstrim.interval = "weekly";

  # ── Coredumps ──────────────────────────────────────────────────────────────
  # Hyprland/apps Wayland crasham e despejam core em /var/lib/systemd/coredump.
  # Sem teto, acumulam (cada core do Hyprland com VRAM mapeada é grande). Mantém
  # capacidade de debug, mas com teto de disco e core gigante descartado.
  systemd.coredump.extraConfig = ''
    Storage=external
    Compress=yes
    MaxUse=1G
    ProcessSizeMax=2G
  '';

  # ── Containers: GC ROOTFUL ─────────────────────────────────────────────────
  # Roda como systemd de sistema → limpa só /var/lib/containers. O lixo do
  # dev-stack é ROOTLESS → ver podman-prune de usuário abaixo (esta opção
  # sozinha NÃO o cobre). O resto do Podman: experiments/podman.nix.
  virtualisation.podman.autoPrune = {
    enable = true;
    dates = "weekly";
    flags = [
      "--all" # remove imagens sem container associado (não só dangling)
      "--filter"
      "until=168h" # poupa o que tem menos de 7 dias
    ];
  };

  # ── Containers: GC ROOTLESS (onde o lixo do dev-stack realmente fica) ───────
  # O autoPrune nativo (acima) roda como root e só limpa o storage rootful. Os
  # containers/imagens do `coruja up`, testcontainers etc. vivem no storage
  # ROOTLESS do usuário (~/.local/share/containers) — precisam deste timer próprio.
  systemd.user.services.podman-prune = {
    description = "Prune podman rootless (imagens/containers/cache não usados há +7d)";
    serviceConfig = {
      Type = "oneshot";
      # --all: remove imagens sem container. until=168h: poupa o que é dos últimos 7 dias.
      # SEM --volumes de propósito — volumes podem guardar dados (DB de testcontainer).
      ExecStart = "${pkgs.podman}/bin/podman system prune --all --force --filter until=168h";
    };
  };
  systemd.user.timers.podman-prune = {
    description = "Agenda semanal do prune podman rootless";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true; # se a máquina estava off no horário, roda no próximo login
    };
  };
}
