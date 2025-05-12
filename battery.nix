{ config, pkgs, ... }:

{
  # # Better scheduling for CPU cycles - thanks System76!!!
  services.system76-scheduler.settings.cfsProfiles.enable = true;

  # # Enable powertop
  powerManagement.powertop.enable = true;
}