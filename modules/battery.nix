{ pkgs, ... }:

{
  services.auto-epp.enable = true;

  services.power-profiles-daemon.enable = true;

  # powerManagement.powertop.enable = true;
  
  services.thermald.enable = true;
  
  services.upower = {
    enable = true;
    percentageLow = 15;
    percentageCritical = 5;
    percentageAction = 3;
    criticalPowerAction = "Hibernate"; # Hiberna em bateria crítica
  };
}
