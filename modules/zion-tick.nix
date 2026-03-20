{ pkgs, ... }:
let
  user = "pedrinho";
  zionBin = "/home/${user}/.local/bin/zion";

  tickScript = pkgs.writeShellScript "zion-tick" ''
    if [ ! -x "${zionBin}" ]; then
      echo "zion-tick: ${zionBin} not found, skipping"
      exit 0
    fi
    export HOME="/home/${user}"
    exec "${zionBin}" tasks tick
  '';
in {
  systemd.services.zion-tick = {
    description = "Zion task tick — executa cards vencidos do kanban";
    after = [ "network.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = user;
      ExecStart = "${tickScript}";
      Environment = [
        "HOME=/home/${user}"
        "PATH=/home/${user}/.local/bin:/run/current-system/sw/bin:/usr/bin:/bin"
      ];
    };
  };

  systemd.timers.zion-tick = {
    description = "Zion task tick a cada 10 minutos";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "10min";
      Unit = "zion-tick.service";
    };
  };
}
