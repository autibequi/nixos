{ ... }:
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        MultiProfile = "on";
        Experimental = true;
        AutoEnable = true;
      };
    };
  };

  # blueman (applet GTK) desativado — pareamento via bluetuith (TUI) / nwg-panel.
  services.blueman.enable = false;
}
