# ════════════════════════════════════════════════════════════════════
# modules/hardware/gpu-toggle.nix
#
# Wrapper runtime sobre `nvidia-offload` — decide se um app vai pra dGPU
# (NVIDIA RTX 4060) ou iGPU (AMD Radeon 780M) baseado em um flag persistente
# + auto-detect de AC. Sem rebuild/reboot pra trocar.
#
# Binários expostos:
#   gpu-offload <cmd> [args...]  — substitui `nvidia-offload` nos call sites
#                                  (gpu-apps.nix, hypr/application.conf)
#   gpu-profile {home|mobile|auto|status}
#                                — controla o estado em /var/lib/gpu-toggle/profile
#
# Resolução:
#   home   → exec nvidia-offload <cmd>   (dGPU via PRIME)
#   mobile → exec <cmd>                  (iGPU AMD, sem env vars)
#   auto   → se AC online → home, senão → mobile
#
# Default após primeiro rebuild: auto (tmpfiles cria o file).
# ════════════════════════════════════════════════════════════════════
{ pkgs, ... }:

let
  user = "pedrinho";
  stateFile = "/var/lib/gpu-toggle/profile";

  gpu-offload = pkgs.writeShellScriptBin "gpu-offload" ''
    profile=$(cat ${stateFile} 2>/dev/null || echo auto)
    if [ "$profile" = "auto" ] || [ -z "$profile" ]; then
      online=$(cat /sys/class/power_supply/AC*/online 2>/dev/null | head -n1)
      if [ "$online" = "1" ]; then
        profile=home
      else
        profile=mobile
      fi
    fi
    case "$profile" in
      home)   exec nvidia-offload "$@" ;;
      mobile) exec "$@" ;;
      *)      exec "$@" ;;
    esac
  '';

  gpu-profile = pkgs.writeShellScriptBin "gpu-profile" ''
    set -e
    case "''${1:-status}" in
      home|mobile|auto)
        echo "$1" > ${stateFile}
        ${pkgs.libnotify}/bin/notify-send "GPU profile" "$1" 2>/dev/null || true
        echo "GPU profile set to: $1"
        ;;
      status)
        raw=$(cat ${stateFile} 2>/dev/null || echo auto)
        echo "Profile: $raw"
        if [ "$raw" = "auto" ] || [ -z "$raw" ]; then
          online=$(cat /sys/class/power_supply/AC*/online 2>/dev/null | head -n1)
          if [ "$online" = "1" ]; then
            echo "Resolved: home (AC online)"
          else
            echo "Resolved: mobile (on battery)"
          fi
        fi
        ;;
      *)
        echo "usage: gpu-profile {home|mobile|auto|status}" >&2
        exit 2
        ;;
    esac
  '';
in
{
  environment.systemPackages = [
    gpu-offload
    gpu-profile
  ];

  # Estado persistente: gravável pelo user, sem sudo.
  systemd.tmpfiles.rules = [
    "d /var/lib/gpu-toggle 0755 ${user} users -"
    "f /var/lib/gpu-toggle/profile 0644 ${user} users - auto"
  ];
}
