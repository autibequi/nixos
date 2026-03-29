{ pkgs, ... }:
let
  user = "pedrinho";
  vennonBin = "/home/${user}/.local/bin/vennon";
  script = pkgs.writeShellScript "vennon-tick" ''
    if [ ! -x "${vennonBin}" ]; then
      echo "vennon-tick: ${vennonBin} not found, skipping"
      exit 0
    fi
    export HOME="/home/${user}"
    exec "${vennonBin}" tick
  '';
in {
  systemd.services.vennon-tick = {
    description = "vennon tick — agents + tasks a cada 10min";
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

  systemd.timers.vennon-tick = {
    description = "vennon tick a cada 10 minutos";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "10min";
      Unit = "vennon-tick.service";
    };
  };
}
