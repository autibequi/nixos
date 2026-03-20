{ ... }:
let
  user = "pedrinho";
  zionBin = "/home/${user}/.local/bin/zion";
in {
  systemd.services.zion-tick = {
    description = "Zion task tick — executa cards vencidos do kanban";
    after = [ "network.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = user;
      ExecStart = "${zionBin} tasks tick";
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
