{ config, pkgs, ... }:

{
  # NixOs stock power management
  powerManagement = {
    powertop.enable = true; # Habilitar powertop para análise e otimização de energia

    # Since running from external NVME, we need to set the correct policy
    # this wont save battery but may help nvme heat
    scsiLinkPolicy = "min_power"; # default is "max_performance"
  };

  # Reduzir o uso de energia da rede quando na bateria
  networking.networkmanager = {
    wifi.powersave = true;
    ethernet.macAddress = "preserve";  # Preservar endereço MAC para economizar energia
  };
  
  # Habilitar thermald para controle térmico
  services.thermald.enable = true;
}