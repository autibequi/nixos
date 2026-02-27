{ ... }:

{
  # Configurações de hibernação e gerenciamento de energia
  # ASUS Zephyrus GA402X: firmware só suporta s2idle (Modern Standby), não S3 deep sleep
  # NVIDIA + s2idle: wake quebrado/tela preta é comum; finegrained=false no nvidia.nix ajuda

  # 25.11: opções top-level e extraConfig removidas; tudo em settings.Login
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend-then-hibernate";
    HandleLidSwitchDocked = "suspend-then-hibernate";
    HandlePowerKey = "hibernate";
    HandlePowerKeyLongPress = "poweroff";
    IdleAction = "suspend-then-hibernate";
    IdleActionSec = "10min";
  };

  systemd.sleep.extraConfig = ''
    AllowSuspend=yes
    AllowHibernation=yes
    AllowSuspendThenHibernate=yes
    SuspendState=freeze
    # Delay maior = mais resumos a partir de suspend (mais estável) que de hibernate
    HibernateDelaySec=30m
    # Tempo após resume antes de subir userspace (NVIDIA/ACPI precisam reinicializar)
    ResumeDelaySec=5
  '';

  # s2idle + params que ajudam wake em ASUS/NVIDIA (evitam re-suspend e EC travando)
  # no_console_suspend: console ativa no resume (se travar, dá pra ver onde no dmesg/journal)
  boot.kernelParams = [
    "mem_sleep_default=s2idle"
    "acpi.ec_no_wakeup=1"
    "no_console_suspend"
  ];

}
