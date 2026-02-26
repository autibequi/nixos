{
  pkgs,
  ...
}:
{
  # Logiops - Unofficial userspace driver for HID++ Logitech devices
  # Remaps MX Master 3 extra buttons via /etc/logid.cfg
  environment.etc."logid.cfg".text = ''
    devices: ({
      name: "Wireless Mouse MX Master 3";
      buttons: ({
        // Side button (forward) -> KEY_F19 -> bound to hyprexpo in Hyprland
        cid: 0xc4;
        action = {
          type: "Keypress";
          keys: ["KEY_F19"];
        };
      });
    });
  '';

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
