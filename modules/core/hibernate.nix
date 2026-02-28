{ ... }:

{
  # Configurações de hibernação e gerenciamento de energia
  # ASUS Zephyrus GA402X: firmware só suporta s2idle (Modern Standby), não S3 deep sleep
  # NVIDIA + s2idle: wake quebrado/tela preta é comum; finegrained=false no nvidia.nix ajuda
  #
  # IMPORTANTE: systemd-logind não reinicia ao aplicar config (restartIfChanged=false no NixOS).
  # Alterações aqui só valem após REBOOT. "nh os switch" não basta para lid close.

  # NixOS 25.05/25.11: só settings.Login (extraConfig e lidSwitch top-level foram removidos)
  # Power: só sleep (suspend). Lid/idle: suspend, depois hibernate em 30min (HibernateDelaySec).
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

  # Fallback: acpid executa suspend-then-hibernate na tampa (sleep, depois hibernate em 30min).
  # -i = ignore inhibitors.
  services.acpid = {
    enable = true;
    lidEventCommands = "systemctl suspend-then-hibernate -i";
  };
}
