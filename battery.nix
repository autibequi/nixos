{ config, pkgs, ... }:

{
  # Disable GNOMEs power management
  services.power-profiles-daemon.enable = true;

  # Not so sure anymore
  # # Better scheduling for CPU cycles - thanks System76!!!
  services.system76-scheduler.settings.cfsProfiles.enable = true;

  # # Enable powertop
  powerManagement.powertop.enable = true;
}