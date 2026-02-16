{ ... }:

{
  # Configurações de hibernação e gerenciamento de energia
  # ASUS Zephyrus GA402X: firmware só suporta s2idle (Modern Standby), não S3 deep sleep
  services.logind = {
    lidSwitch = "suspend-then-hibernate";
    lidSwitchExternalPower = "suspend-then-hibernate";
    lidSwitchDocked = "suspend-then-hibernate";
    powerKey = "hibernate";
    powerKeyLongPress = "poweroff";
  };

  systemd.sleep.extraConfig = ''
    AllowSuspend=yes
    AllowHibernation=yes
    AllowSuspendThenHibernate=yes
    SuspendState=freeze
    HibernateDelaySec=15m
  '';

  # s2idle é o único estado disponível nesse hardware — não forçar deep
  boot.kernelParams = [
    "mem_sleep_default=s2idle"
  ];

  # TTY Sleep
  services.logind.extraConfig = ''
    IdleAction=suspend-then-hibernate
    IdleActionSec=15min
  '';
}
