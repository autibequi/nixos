{ pkgs, ... }:
let
  user = "pedrinho";
  leechBin = "/home/${user}/.local/bin/leech";
  script = pkgs.writeShellScript "leech-tick" ''
    if [ ! -x "${leechBin}" ]; then
      echo "leech-tick: ${leechBin} not found, skipping"
      exit 0
    fi
    export HOME="/home/${user}"
    exec "${leechBin}" tick
  '';
in {
  systemd.services.leech-tick = {
    description = "Leech tick — agents + tasks a cada 10min";
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

  systemd.timers.leech-tick = {
    description = "Leech tick a cada 10 minutos";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "10min";
      Unit = "leech-tick.service";
    };
  };
}
