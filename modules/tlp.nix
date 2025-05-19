{ config, pkgs, ... }:

{
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
      
      # Desabilitar o watchdog do kernel
      NMI_WATCHDOG = 0;

      MEM_SLEEP_ON_AC = "s2idle";
      MEM_SLEEP_ON_BAT = "deep";

      # ASPM Runtime
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";

      #ASPM
      PCIE_ASPM_ON_AC = "performance";
      PCIE_ASPM_ON_BAT = "powersupersave";

      #USB
      USB_AUTOSUSPEND = 1;
      USB_SUSPEND_RESUME_DELAY = 2;

      #Bluetooth
      BLUETOOTH_PM_PROTOCOL_OFF_BAT = "h4";
      BLUETOOTH_PM_PROTOCOL_ON_AC = "h4";

      #Wifi
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
    };
  };
}