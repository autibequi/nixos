{ config, pkgs, ... }:

{
  imports = [
    # ./tlp.nix # importe para não usar o power-profile-daemon do gnome
  ];

  # NixOs stock power management
  powerManagement.powertop.enable = true;

  # System76 scheduler
  services.system76-scheduler.settings.cfsProfiles.enable = true;

  # Battery power management
  systemd.sleep.extraConfig = ''
    AllowSuspend=yes
    AllowHibernation=no
  '';

  # Kernel parameters
  boot.kernelParams = [ "mem_sleep_default=deep" ];
}