{ ... }:

{
  imports = [
    # Too much trouble, pstate does the same with better perf
    # ./tlp.nix
  ];

  # NixOs stock power management
  powerManagement.powertop.enable = true;

  # AMD EPP to change the power profile so pstate can change
  services.auto-epp.enable = true;

  # Hibernation
  # NVME case swap partition
  boot.resumeDevice = "/dev/disk/by-uuid/4265d4f9-7f7b-4ebf-a3b4-a3406c3c0955";

  services.logind = {
    lidSwitch = "hibernate";
    powerKey = "hibernate";
    powerKeyLongPress = "poweroff";
  };

  # Kernel parameters para hibernação - FIXED!
  boot.kernelParams = [
    "mem_sleep_default=deep"
  ];
}
