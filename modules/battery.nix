{ pkgs, lib, ... }:

{
  # TLP (tlp.nix) desliga o PPD quando ativo; sem TLP, PPD fica ativo
  services.power-profiles-daemon.enable = lib.mkDefault true;

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
