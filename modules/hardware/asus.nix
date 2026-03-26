{ ... }:
{
  # curent setup g14
  programs.rog-control-center = {
    enable = true;
    autoStart = false; # crashava 12x — GUI desabilitado no boot, asusd/supergfxd continuam ativos
  };

  services = {
    asusd = {
      enable = true;
      enableUserService = true;
    };
    supergfxd = {
      enable = true;
    };
  };

  services.supergfxd.settings = {
    mode = "Hybrid";
    vfio_enable = false;
    vfio_save = false;
    always_reboot = false;
    no_logind = true;
    logout_timeout_s = 180;
    hotplug_type = "None";
  };


  boot.kernelModules = [
    "asus_nb_wmi"
    "asus_wmi"
  ];
}
