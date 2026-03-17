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

  # Media (ffmpeg/python3 removidos — usar nix-shell -p sob demanda)
  yt-dlp
  sox

  # System
  util-linux      # flock for puppy-runner
  systemdMinimal  # journalctl
  procps          # ps, top, free

  # Wayland
  wl-clipboard

  # GitHub CLI
  gh

  # Nix (superpoderes: nix-shell -p dentro do container)
  nix

  # Docker CLI (socket forwarding pro Podman do host)
  docker-client
]
