{ pkgs, ... }:
let
  user = "pedrinho";
  zionBin = "/home/${user}/.local/bin/zion";

  workScript = pkgs.writeShellScript "zion-agents-work" ''
    if [ ! -x "${zionBin}" ]; then
      echo "zion-agents-work: ${zionBin} not found, skipping"
      exit 0
    fi
    export HOME="/home/${user}"
    exec "${zionBin}" agents work
  '';

in {
  systemd.services.zion-agents-work = {
    description = "Zion agents work — executa agent cards vencidos do schedule";
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = user;
      ExecStart = "${workScript}";
      Environment = [
        "HOME=/home/${user}"
        "PATH=/home/${user}/.local/bin:/run/current-system/sw/bin:/usr/bin:/bin"
      ];
    };
  };

  systemd.timers.zion-agents-work = {
    description = "Zion agents work — a cada 10 minutos";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "6min";
      OnUnitActiveSec = "10min";
      Unit = "zion-agents-work.service";
    };
  };
}
