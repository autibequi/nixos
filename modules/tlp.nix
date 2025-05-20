{ config, pkgs, ... }:

{
  # Desabilitar power-profiles-daemon para evitar conflitos com o TLP
  services.power-profiles-daemon.enable = false;

  services.tlp = {
    enable = true;
    settings = {
      # powersave on battery for nvme case
      SATA_LINKPWR_ON_BAT = "med_power_with_dipm";

      # AC (conectado à energia)
      # cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
      ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_BOOST_ON_AC = 1; 
      CPU_MIN_PERF_ON_AC=0;
      CPU_MAX_PERF_ON_AC=100;

      # Battery (na bateria)
      ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_BOOST_ON_BAT = 0; # pode ser util devido a scx_lavd que agrupa as threads em poucos cores??
      CPU_MIN_PERF_ON_BAT=0;
      CPU_MAX_PERF_ON_BAT=30;

      # CPU Driver
      # must be passive/guided for userland schedulers
      # but active is better for battery life
      CPU_DRIVER_OPMODE_ON_AC = "passive";
      CPU_DRIVER_OPMODE_ON_BAT = "active"; 

      # Desabilitar o watchdog do kernel
      MEM_SLEEP_ON_AC = "s2idle";
      MEM_SLEEP_ON_BAT = "deep";

      # ASPM Runtime
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";

      # plataform
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      # CPU Energy Policy
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # ASPM
      PCIE_ASPM_ON_AC = "performance";
      PCIE_ASPM_ON_BAT = "powersupersave";

      # USB
      USB_AUTOSUSPEND = 1;
      USB_SUSPEND_RESUME_DELAY = 2;

      # Wifi
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
      
      # Enable display panel Adaptive Backlight Modulation (ABM).
      # not sure if save battery but makes image blew out:
      # AMDGPU_ABM_LEVEL_ON_AC = 0;
      # AMDGPU_ABM_LEVEL_ON_BAT = 4; # 0-4
    };
  };
}