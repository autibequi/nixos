{ ... }:

{
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend-then-hibernate";
    HandleLidSwitchDocked = "suspend-then-hibernate";
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
    # Idle gerenciado pelo hypridle — sem IdleAction aqui pra evitar corrida
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
  ];
}
