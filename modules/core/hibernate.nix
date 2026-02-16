{ ... }:

{
  # Configurações de hibernação e gerenciamento de energia
  # ASUS Zephyrus GA402X: firmware só suporta s2idle (Modern Standby), não S3 deep sleep
  # NVIDIA + s2idle: wake quebrado/tela preta é comum; finegrained=false no nvidia.nix ajuda
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
    # Delay maior = mais resumos a partir de suspend (mais estável) que de hibernate
    HibernateDelaySec=30m
  '';

  # s2idle + params que ajudam wake em ASUS/NVIDIA (evitam re-suspend e EC travando)
  boot.kernelParams = [
    "mem_sleep_default=s2idle"
    "acpi.ec_no_wakeup=1"
  ];

  # TTY Sleep (se ainda acordar quebrado, troque IdleAction para "suspend")
  services.logind.extraConfig = ''
    HandleLidSwitchDocked=suspend-then-hibernate
    IdleAction=suspend-then-hibernate
    IdleActionSec=10min
  '';
}
