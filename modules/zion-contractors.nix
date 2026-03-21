{ pkgs, ... }:
let
  user = "pedrinho";
  zionBin = "/home/${user}/.local/bin/zion";

  workScript = pkgs.writeShellScript "zion-contractors-work" ''
    if [ ! -x "${zionBin}" ]; then
      echo "zion-contractors-work: ${zionBin} not found, skipping"
      exit 0
    fi
    export HOME="/home/${user}"
    exec "${zionBin}" contractors work
  '';

in {
  systemd.services.zion-contractors-work = {
    description = "Zion contractors work — executa contractor cards vencidos do kanban";
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

  systemd.timers.zion-contractors-work = {
    description = "Zion contractors work — a cada 10 minutos";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "6min";
      OnUnitActiveSec = "10min";
      Unit = "zion-contractors-work.service";
    };
  };
}
