{ pkgs, ... }:
let
  user = "pedrinho";
  zionBin = "/home/${user}/.local/bin/zion";
  script = pkgs.writeShellScript "zion-tick" ''
    if [ ! -x "${zionBin}" ]; then
      echo "zion-tick: ${zionBin} not found, skipping"
      exit 0
    fi
    export HOME="/home/${user}"
    exec "${zionBin}" tick
  '';
in {
  systemd.services.zion-tick = {
    description = "Zion tick — agents + tasks a cada 10min";
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = user;
      ExecStart = "${script}";
      Environment = [
        "HOME=/home/${user}"
        "PATH=/home/${user}/.local/bin:/run/current-system/sw/bin:/usr/bin:/bin"
      ];
    };
  };

  systemd.timers.zion-tick = {
    description = "Zion tick a cada 10 minutos";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "10min";
      Unit = "zion-tick.service";
    };
  };
}
