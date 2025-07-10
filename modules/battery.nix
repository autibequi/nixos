{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    powertop # power management
  ];

  # Tweak CFS latency parameters when going on/off battery
  services.system76-scheduler.settings.cfsProfiles.enable = true;

  # NixOs stock power management
  powerManagement.powertop.enable = true;

  # AMD EPP to change the power profile so pstate can change
  services.auto-epp.enable = true;
}
