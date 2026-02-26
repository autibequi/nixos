{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    logiops
  ];

  environment.etc."logid.cfg".source = ./logid.cfg;

  systemd.services.logiops = {
    description = "Unofficial userspace driver for HID++ Logitech devices (MX Master 3)";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.logiops}/bin/logid";
      Restart = "on-failure";
    };
  };
}
