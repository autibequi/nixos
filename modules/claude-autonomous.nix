{ pkgs, ... }:
let
  user = "pedrinho";
  projectDir = "/home/${user}/projects/nixos";
  compose = "${pkgs.docker-compose}/bin/docker-compose -f ${projectDir}/docker-compose.claude.yml";
in {
  systemd.services.claude-autonomous = {
    description = "Claudinho autonomous task runner";
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = user;
      WorkingDirectory = projectDir;
      ExecStart = "${pkgs.bash}/bin/bash -c '${compose} up -d sandbox && ${compose} exec -T sandbox bash /workspace/scripts/clau-runner.sh'";
      TimeoutStopSec = "12min";
      Environment = [ "HOME=/home/${user}" "XDG_RUNTIME_DIR=/run/user/1000" "DOCKER_HOST=unix:///run/podman/podman.sock" ];
    };
  };

  systemd.timers.claude-autonomous = {
    description = "Run Claudinho tasks 10min every hour";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "minutely";
      RandomizedDelaySec = "5min";
      Persistent = true;
    };
  };
}
