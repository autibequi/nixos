{ ... }:

{
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "suspend";
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
    IdleAction = "suspend-then-hibernate";
    IdleActionSec = "10min";
  };

  systemd.sleep.extraConfig = ''
    AllowSuspend=yes
    AllowHibernation=yes
    AllowSuspendThenHibernate=yes
    SuspendState=freeze
    HibernateDelaySec=30m
  '';

  boot.kernelParams = [
    "mem_sleep_default=s2idle"
    "acpi.ec_no_wakeup=1"
    "no_console_suspend"
  ];
}
