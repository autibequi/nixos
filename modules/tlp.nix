{ config, pkgs, ... }:

{
  # Desabilitar power-profiles-daemon para evitar conflitos com o TLP
  services.power-profiles-daemon.enable = false;

  services.tlp = {
    enable = true;
    settings = {
      # powersave on battery
      SATA_LINKPWR_ON_BAT = "med_power_with_dipm";

      # AC (conectado à energia)
      # cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
      ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_AC = "schedutil";
      CPU_BOOST_ON_AC = 1; 

      # Battery (na bateria)
      ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_SCALING_GOVERNOR_ON_BAT = "schedutil";
      CPU_BOOST_ON_BAT = 0; 

      # CPU Driver
      CPU_DRIVER_OPMODE_ON_AC = "active";
      CPU_DRIVER_OPMODE_ON_BAT = "active";

      # Desabilitar o watchdog do kernel
      NMI_WATCHDOG = 0;

      MEM_SLEEP_ON_AC = "s2idle";
      MEM_SLEEP_ON_BAT = "deep";

      # ASPM Runtime
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";

      # plataform
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      #ASPM
      PCIE_ASPM_ON_AC = "performance";
      PCIE_ASPM_ON_BAT = "powersupersave";

      #USB
      USB_AUTOSUSPEND = 1;
      USB_SUSPEND_RESUME_DELAY = 2;

      #Wifi
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
      
      # Enable display panel Adaptive Backlight Modulation (ABM).:
      # Makes image blurrier, not sure if saves battery
      AMDGPU_ABM_LEVEL_ON_AC = 0;
      AMDGPU_ABM_LEVEL_ON_BAT = 4; # 0-4
    };
  };
}