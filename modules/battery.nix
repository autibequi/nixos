{ config, pkgs, ... }:

{
  imports = [
    # doubles battery life on g14 2023
    # ./tlp.nix 
  ];

  # NixOs stock power management
  powerManagement.powertop.enable = true;

  # System76 scheduler
  services.system76-scheduler.settings.cfsProfiles.enable = true;

  # Melhora consumo idle da GPU nvidia
  hardware.nvidia.nvidiaPersistenced = false;
}