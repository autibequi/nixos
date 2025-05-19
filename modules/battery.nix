{ config, pkgs, ... }:

{
  # NixOs stock power management
  powerManagement.powertop.enable = true;

  # Desabilitar power-profiles-daemon para evitar conflitos com o TLP
  services.power-profiles-daemon.enable = false;

  services.tlp = {
    enable = true;
    settings = {
      # Throttle CPU on battery
      CPU_MAX_PERF_ON_BAT = 10;

      # Boost CPU on AC
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      # Use power policy on battery
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

      # Throttle GPU on battery
      RADEON_POWER_PROFILE_ON_AC = "high";
      RADEON_POWER_PROFILE_ON_BAT = "low";

      # Keep WiFi on battery
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