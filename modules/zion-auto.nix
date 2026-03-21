{ pkgs, ... }:
let
  user = "pedrinho";
  zionBin = "/home/${user}/.local/bin/zion";
  script = pkgs.writeShellScript "zion-auto" ''
    if [ ! -x "${zionBin}" ]; then
      echo "zion-auto: ${zionBin} not found, skipping"
      exit 0
    fi
    export HOME="/home/${user}"
    exec "${zionBin}" auto
  '';
in {
  systemd.services.zion-auto = {
    description = "Zion auto — agents + tasks a cada 10min";
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

  systemd.timers.zion-auto = {
    description = "Zion auto a cada 10 minutos";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "10min";
      Unit = "zion-auto.service";
    };
  };
}
