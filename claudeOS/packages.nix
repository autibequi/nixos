{ pkgs }:

with pkgs; [
  # Shell essentials
  bashInteractive
  coreutils
  gnugrep
  gnused
  findutils
  gnutar
  gzip
  which
  less

  # Dev tools
  git
  jq
  curl
  python3
  nodejs

  # Media
  yt-dlp
  ffmpeg
  sox

  # System
  util-linux      # flock pro clau-runner
  systemdMinimal  # journalctl
  procps          # ps, top, free

  # Wayland
  wl-clipboard

  # GitHub CLI
  gh

  # Nix já vem da imagem base (nixos/nix:latest) — não incluir aqui pra evitar
  # conflito de nix-daemon.service. Superpoderes (nix-shell -p) funcionam normalmente.

  # Docker CLI (socket forwarding pro Podman do host)
  docker-client
]
