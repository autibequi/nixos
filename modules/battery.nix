{ config, pkgs, ... }:

{
  # NixOs stock power management
  powerManagement = {
    # Habilitar powertop para análise e otimização de energia
    powertop.enable = true;

    # Devido ao uso de SSDs NVMe, o modo de energia "med_power_with_dipm" é mais adequado
    # poupando o disco para maior desempenho a longo prazo devido a heating e permitindo sleep.
    scsiLinkPolicy = "med_power_with_dipm"; 
  };
}