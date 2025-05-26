{ config, pkgs, ... }:

{
  imports = [
    # Too much trouble, pstate does the same with better perf
    # ./tlp.nix
  ];

  # NixOs stock power management
  powerManagement.powertop.enable = true;

  # System76 scheduler
  services.system76-scheduler.settings.cfsProfiles.enable = true;

  # Melhora consumo idle da GPU nvidia
  hardware.nvidia.nvidiaPersistenced = false;

  # AMD EPP to change the power profile so pstate can change
  services.auto-epp.enable = true;

  # Hibernação e suspend configurações
  services.logind = {
    lidSwitch = "suspend-then-hibernate";
    lidSwitchExternalPower = "suspend-then-hibernate";
  };

  # Configurações de sleep para suspend-then-hibernate
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=20min
    SuspendState=mem
    HibernateMode=platform
  '';

  # Configurações de kernel para deep sleep
  boot.kernelParams = ["mem_sleep_default=deep"];
}