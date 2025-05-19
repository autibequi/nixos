{ config, pkgs, ... }:

{
  # NixOs stock power management
  powerManagement.powertop.enable = true;

  # Desabilitar power-profiles-daemon para evitar conflitos com o TLP
  services.power-profiles-daemon.enable = false;

  services.tlp = {
    enable = true;
    settings = {
      # AC (conectado à energia)
      # cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_BOOST_ON_AC = 1; 

      # Battery (na bateria)
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_BOOST_ON_BAT = 0; 
      CPU_MAX_PERF_ON_BAT = 10; 

      # Power policy
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power"; 
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance"; 
      

      # Configurações de GPU AMD (mantidas)
      RADEON_POWER_PROFILE_ON_AC = "high";
      RADEON_POWER_PROFILE_ON_BAT = "low";
      RADEON_DPM_STATE_ON_AC = "performance";
      RADEON_DPM_STATE_ON_BAT = "battery";
      AMDGPU_ABM_LEVEL_ON_AC = 0;
      AMDGPU_ABM_LEVEL_ON_BAT = 4;
      
      # Outras configurações (mantidas)
      WIFI_PWR_ON_BAT = "on";
    };
  };

  services.system76-scheduler.settings.cfsProfiles.enable = true;

  systemd.sleep.extraConfig = ''
    AllowSuspend=yes
    AllowHibernation=no
  '';

  boot.kernelParams = [ "mem_sleep_default=deep" ];
}