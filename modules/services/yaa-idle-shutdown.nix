{ config, pkgs, lib, ... }:
# yaa-idle-shutdown — para o container yaa automaticamente após N minutos de inatividade.
#
# Mecanismo:
#   • O hook stop.sh dentro do container toca /run/user/UID/yaa/activity/last-turn
#     a cada fim de turno do agente.
#   • Este timer verifica o mtime desse arquivo a cada 5 minutos.
#   • Se mtime > YAA_IDLE_SHUTDOWN minutos (lido de ~/yaa.yaml) → `yaa <container> stop`.
#   • 0 ou ausente em yaa.yaml = desabilitado.
#
# Ativar: adicionar ao imports em modules/services/default.nix

let
  checkScript = pkgs.writeShellScript "yaa-idle-check" ''
    set -uo pipefail
    PATH="${pkgs.coreutils}/bin:${pkgs.jq}/bin:${pkgs.gawk}/bin:${lib.makeBinPath [ pkgs.curl pkgs.socat ]}:$PATH"

    YAA_YAML="$HOME/yaa.yaml"
    ACTIVITY_FILE="/run/user/$(id -u)/yaa/activity/last-turn"
    PODMAN_SOCK="/run/user/$(id -u)/podman/podman.sock"

    # Lê limiar (minutos) do yaa.yaml
    threshold=0
    if [ -f "$YAA_YAML" ]; then
      threshold="$(grep -E '^YAA_IDLE_SHUTDOWN:' "$YAA_YAML" \
                    | awk '{print $2}' | tr -d '"'"'"' ' | head -1)"
    fi
    threshold="''${threshold:-60}"

    # 0 = desabilitado
    [[ "$threshold" =~ ^[0-9]+$ ]] || exit 0
    [ "$threshold" -eq 0 ] && exit 0

    # Sem arquivo de atividade: container nunca teve turno — não derrubar
    [ -f "$ACTIVITY_FILE" ] || exit 0

    last_epoch=$(stat -c %Y "$ACTIVITY_FILE" 2>/dev/null) || exit 0
    now_epoch=$(date +%s)
    idle_seconds=$(( now_epoch - last_epoch ))
    threshold_seconds=$(( threshold * 60 ))

    [ "$idle_seconds" -le "$threshold_seconds" ] && exit 0

    # Verifica se o container ainda está rodando via Podman socket
    # Container name pattern: yaa_<slug>
    running=$(curl -sf --unix-socket "$PODMAN_SOCK" \
      'http://d/v4.0.0/libpod/containers/json?all=false' 2>/dev/null \
      | jq -r '[.[] | select(.Names[] | startswith("yaa_")) | .Names[]] | first // ""')

    [ -z "$running" ] && exit 0   # nenhum container yaa rodando

    idle_min=$(( idle_seconds / 60 ))
    echo "[yaa-idle-check] $(date '+%Y-%m-%d %H:%M:%S') — $running idle ${idle_min}m >= ${threshold}m → parando"
    yaa "$( echo "$running" | sed 's/^yaa_//' )" stop 2>&1 || true
  '';
in
{
  systemd.user.services.yaa-idle-check = {
    description = "Verifica inatividade e para o container yaa se ocioso";
    path = [ pkgs.yaa or pkgs.coreutils pkgs.jq pkgs.curl pkgs.gawk ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${checkScript}";
      Environment = "PATH=%h/.local/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin";
    };
  };

  systemd.user.timers.yaa-idle-check = {
    description = "Timer de idle-check do container yaa (a cada 5 min)";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "5min";
      Unit = "yaa-idle-check.service";
    };
  };
}
