{ pkgs, ... }:
let
  user = "pedrinho";
  zionBin = "/home/${user}/.local/bin/zion";

  # Contractors com timer automático: { name, onBootSec, onActiveSec }
  scheduled = [
    { name = "tamagochi"; onBootSec = "3min";  onActiveSec = "10min"; }
    { name = "wanderer";  onBootSec = "5min";  onActiveSec = "60min"; }
  ];

  mkScript = name: pkgs.writeShellScript "zion-contractor-${name}" ''
    if [ ! -x "${zionBin}" ]; then
      echo "zion-contractor-${name}: ${zionBin} not found, skipping"
      exit 0
    fi
    export HOME="/home/${user}"
    exec "${zionBin}" contractors run "${name}"
  '';

  mkService = { name, ... }: {
    "zion-contractor-${name}" = {
      description = "Zion contractor — ${name}";
      after = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = user;
        ExecStart = "${mkScript name}";
        Environment = [
          "HOME=/home/${user}"
          "PATH=/home/${user}/.local/bin:/run/current-system/sw/bin:/usr/bin:/bin"
        ];
      };
    };
  };

  mkTimer = { name, onBootSec, onActiveSec }: {
    "zion-contractor-${name}" = {
      description = "Zion contractor ${name} — a cada ${onActiveSec}";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = onBootSec;
        OnUnitActiveSec = onActiveSec;
        Unit = "zion-contractor-${name}.service";
      };
    };
  };

in {
  systemd.services = builtins.foldl' (acc: c: acc // mkService c) {} scheduled;
  systemd.timers  = builtins.foldl' (acc: c: acc // mkTimer  c) {} scheduled;
}
