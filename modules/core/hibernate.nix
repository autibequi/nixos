{ ... }:

{
  # Workaround: driver NVIDIA proprietário conflita com systemd freeze da user session
  # no suspend → resume traz tela preta/travada. Ver nixpkgs#371058.
  systemd.services.systemd-suspend.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";
  systemd.services.systemd-hibernate.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";
  systemd.services.systemd-hybrid-sleep.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";

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
