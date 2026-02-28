{ pkgs, lib, ... }:

{

  # UPower: monitora bateria e define ações em níveis críticos
  # ignoreLid = true: upower não reage à tampa; logind (hibernate.nix) trata lid close.
  services.upower = {
    enable = true;
    ignoreLid = true;
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
    # dirty_writeback em 10s é um bom meio-termo para NVMe:
    # reduz wakeups de writeback sem causar stalls longos de 15s.
    # (padrão do kernel: 5s; laptop_mode antigo chegava a 15s — ruim para SSDs)
    "vm.dirty_writeback_centisecs" = 1000; # 10 segundos

    # laptop_mode É UM MECANISMO DOS ANOS 2000 PARA HDDs.
    # Em NVMe causa stalls de I/O agrupados (até dirty_writeback_centisecs),
    # tornando o sistema claramente menos responsivo. NUNCA use com SSD/NVMe.
    "vm.laptop_mode" = 0;
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
