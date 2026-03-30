{ ... }:

{
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "suspend";
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
    # Idle gerenciado pelo hypridle — sem IdleAction aqui pra evitar corrida
  };

  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowSuspendThenHibernate=no
  '';

  boot.kernelParams = [
    "mem_sleep_default=s2idle"
    "acpi.ec_no_wakeup=1"
  ];
}
