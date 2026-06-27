{ ... }:

{
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "suspend";
    HandlePowerKey = "poweroff";
    HandlePowerKeyLongPress = "poweroff";
    # Idle gerenciado pelo hypridle — sem IdleAction aqui pra evitar corrida
  };

  systemd.sleep.settings.Sleep = {
    AllowSuspend = true;
    AllowHibernation = true;
    AllowSuspendThenHibernate = true;
    SuspendState = "freeze";
    HibernateDelaySec = "30m";
  };

  boot.kernelParams = [
    "mem_sleep_default=s2idle"
    "acpi.ec_no_wakeup=1"
  ];
}
