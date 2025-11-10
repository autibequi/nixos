{ pkgs, ... }:

{
  # ═══ CPU Scheduler Tweaks ═══
  # Ajusta latency do CFS (Completely Fair Scheduler) quando muda AC/Battery
  services.system76-scheduler = {
    enable = true;
    settings.cfsProfiles.enable = true;
  };

  # ═══ AMD EPP (Energy Performance Preference) ═══
  # Auto-ajusta EPP baseado em carga da bateria (power_save <-> performance)
  # Funciona com amd_pstate=guided do kernel
  services.auto-epp = {
    enable = true;
    settings = {
      # Perfis mais agressivos de economia
      charger = {
        energy_performance_preference = "balance_performance";
        scaling_governor = "schedutil";
      };
      battery = {
        energy_performance_preference = "power"; # Max economy
        scaling_governor = "schedutil";
        turbo = "never"; # Desabilita turbo em bateria
      };
    };
  };

  # ═══ Power Profiles Daemon ═══
  # Integração com GNOME/Desktop para perfis de energia
  # Trabalha em harmonia com auto-epp
  services.power-profiles-daemon.enable = true;

  # ═══ PowerTOP Auto-Tuning ═══
  # Aplica automaticamente todas sugestões de economia do powertop
  powerManagement.powertop.enable = true;
  
  # ═══ Thermald (Intel/AMD Thermal Management) ═══
  # Gerenciamento térmico inteligente para prevenir throttling
  services.thermald.enable = true;
  
  # ═══ upower - Battery Info & Policies ═══
  services.upower = {
    enable = true;
    percentageLow = 15;
    percentageCritical = 5;
    percentageAction = 3;
    criticalPowerAction = "Hibernate"; # Hiberna em bateria crítica
  };
}
