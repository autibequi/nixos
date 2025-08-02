{ ... }:

{
  # Configurações de hibernação e gerenciamento de energia
  services.logind = {
    lidSwitch = "suspend-then-hibernate";
    powerKey = "hibernate";
    powerKeyLongPress = "poweroff";
  };

  systemd.sleep.extraConfig = ''
    HibernateOnACPower=true
    HibernateDelaySec=30m
    SuspendState=mem
  '';

  boot.kernelParams = [
    "mem_sleep_default=deep"
  ];
}
