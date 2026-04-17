{ unstable, ... }:

{
  environment.systemPackages = [ unstable.openclaw ];

  systemd.user.services.openclaw-gateway = {
    description = "OpenClaw Gateway";
    wantedBy = [ "default.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      ExecStart = "${unstable.openclaw}/bin/openclaw gateway";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
