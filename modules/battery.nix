{ pkgs, lib, config, ... }:

{
  # Power Profiles Daemon (PPD) - gerencia perfis de energia
  # Nota: Pode conflitar com auto-epp, mas funciona bem em conjunto se configurado corretamente
  # Desabilite se preferir usar apenas TLP (mais agressivo)
  services.power-profiles-daemon.enable = lib.mkDefault true;

  # Powertop: análise + auto-tune (aplica otimizações automáticas)
  powerManagement.powertop.enable = true;

  # UPower: monitora bateria e define ações em níveis críticos
  services.upower = {
    enable = true;
    percentageLow = 15;
    percentageCritical = 5;
    percentageAction = 3;
    criticalPowerAction = "Hibernate"; # Hiberna em bateria crítica
  };

  # Runtime Power Management para dispositivos PCI/PCIe
  powerManagement.enable = true;

  # WiFi Power Saving
  networking.networkmanager.wifi.powersave = true;

  # Ajustes adicionais de energia via sysctl
  boot.kernel.sysctl = {
    # Controle de writeback (reduz writes em disco)
    "vm.dirty_writeback_centisecs" = 1500; # 15 segundos (padrão: 5s)
    "vm.laptop_mode" = 5; # Ativa laptop mode (agrupa I/O)
  };

  # Ambiente para aplicações (algumas respeitam essas variáveis)
  environment.sessionVariables = {
    # Mesa (GPU): power saving
    RADV_PERFTEST = "nggc"; # AMD RDNA optimizations
    AMD_VULKAN_ICD = "RADV";
  };

  # Pacotes úteis para diagnóstico de bateria
  environment.systemPackages = with pkgs; [
    powertop      # Monitor de consumo
    acpi          # Info de bateria via CLI
    # tlp         # Descomente se quiser usar TLP ao invés de PPD
  ];
}
