{ config, pkgs, ... }:

{
  # NixOs stock power management
  powerManagement = {
    powertop.enable = true; # Habilitar powertop para análise e otimização de energia

    # Since running from external NVME, we need to set the correct policy
    # this wont save battery but may help nvme heat
    scsiLinkPolicy = "med_power_with_dipm"; # default is "max_performance"
  };

  # Habilitar modo de economia de energia para Wi-Fi
  networking.networkmanager.wifi.powersave = true; 
  
  # Habilitar thermald para controle térmico
  services.thermald.enable = true;
}