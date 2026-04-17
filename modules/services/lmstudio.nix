# LM Studio Server Configuration
# Runs LM Studio as a headless API server on 192.168.68.60:1234

{
  config,
  lib,
  pkgs,
  unstable,
  ...
}:

with lib;

let
  cfg = config.services.lmstudio;
in

{
  options.services.lmstudio = {
    enable = mkEnableOption "LM Studio API server";

    port = mkOption {
      type = types.int;
      default = 1234;
      description = "Port for LM Studio API server";
    };

    host = mkOption {
      type = types.str;
      default = "192.168.68.60";
      description = "Host/IP to bind LM Studio API server";
    };

    user = mkOption {
      type = types.str;
      default = "lmstudio";
      description = "User to run LM Studio service";
    };

    group = mkOption {
      type = types.str;
      default = "lmstudio";
      description = "Group for LM Studio service";
    };
  };

  config = mkIf cfg.enable {
    # Ensure lmstudio package is available
    environment.systemPackages = with unstable; [
      lmstudio
    ];

    # Create dedicated user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = "/var/lib/lmstudio";
      createHome = true;
      description = "LM Studio service user";
    };

    users.groups.${cfg.group} = { };

    # Systemd service
    systemd.services.lmstudio = {
      description = "LM Studio API Server";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${unstable.lmstudio}/bin/lms server start --host ${cfg.host} --port ${toString cfg.port}";
        Restart = "on-failure";
        RestartSec = 5;
        StandardOutput = "journal";
        StandardError = "journal";

        # Security
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ "/var/lib/lmstudio" ];
      };
    };

    # Open firewall port
    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
