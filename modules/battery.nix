{ config, pkgs, ... }:

{
  imports = [
    ./tlp.nix # importe para não usar o power-profile-daemon do gnome
  ];

  # NixOs stock power management
  powerManagement.powertop.enable = true;

  # System76 scheduler
  services.system76-scheduler.settings.cfsProfiles.enable = true;

  boot.kernelParams = [ 
    "pcie_aspm=force" # Força o ASPM (Active State Power Management) do PCIe para reduzir o consumo de energia dos dispositivos PCIe quando ocioso
    "pcie_port_pm=on" # Habilita gerenciamento de energia para portas PCIe, reduzindo consumo quando não em uso
  ];

  # Melhora consumo idle da GPU nvidia
  hardware.nvidia.nvidiaPersistenced = true; # Mantém o daemon NVIDIA persistente para melhor desempenho
}