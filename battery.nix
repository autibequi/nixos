{ config, pkgs, ... }:

{
  # Enable TLP (better than gnomes internal power manager)
  # services.tlp = {
  #   enable = true;
  #   settings = {
  #     CPU_BOOST_ON_AC = 1;
  #     CPU_BOOST_ON_BAT = 0;
  #     CPU_SCALING_GOVERNOR_ON_AC = "performance";
  #     CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
  #   };
  # };

  # Disable GNOMEs power management
  services.power-profiles-daemon.enable = true;

  # Not so sure anymore
  # # Better scheduling for CPU cycles - thanks System76!!!
  # services.system76-scheduler.settings.cfsProfiles.enable = true;

  # # Enable powertop
  # powerManagement.powertop.enable = true;
}