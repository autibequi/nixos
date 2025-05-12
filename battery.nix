{ config, pkgs, ... }:

{
  # Melhor agendamento para ciclos de CPU - graças ao System76!!!
  services.system76-scheduler.settings.cfsProfiles.enable = true;

  # Habilitar powertop para análise e otimização de energia
  powerManagement = {
    powertop.enable = true;
  };

  # Reduzir o uso de energia da rede quando na bateria
  networking.networkmanager = {
    wifi.powersave = true;
    ethernet.macAddress = "preserve";  # Preservar endereço MAC para economizar energia
  };
  
  # Habilitar thermald para controle térmico
  services.thermald.enable = true;
}