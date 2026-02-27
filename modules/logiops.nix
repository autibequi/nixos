{
  pkgs,
  config,
  ...
}:
let
  user = "pedrinho";
  configPath = "${config.users.users.${user}.home}/.config/logiops/logid.cfg";
in
{
  environment.systemPackages = with pkgs; [ logiops ];

  systemd.services.logiops = {
    description = "Unofficial userspace driver for HID++ Logitech devices";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      ExecStart = "${pkgs.logiops}/bin/logid -c ${configPath}";
    };
  };
}
