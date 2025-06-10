{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    powertop # power management
  ];

  imports = [
    # Too much trouble, pstate does the same with better perf
    # ./tlp.nix
  ];

  # Tweak CFS latency parameters when going on/off battery
  services.system76-scheduler.settings.cfsProfiles.enable = true;

  # NixOs stock power management
  powerManagement.powertop.enable = true;

  # AMD EPP to change the power profile so pstate can change
  services.auto-epp.enable = true;

  services.logind = {
    lidSwitch = "hibernate";
    powerKey = "hibernate";
    powerKeyLongPress = "poweroff";
  };

  systemd.sleep.extraConfig = ''
    HibernateOnACPower=true
    HibernateDelaySec=10s
  '';

  boot.kernelParams = [
    "mem_sleep_default=deep"
  ];
}
