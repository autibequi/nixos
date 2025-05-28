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
}
