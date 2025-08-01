{ ... }:
{
  # curent setup g14
  programs.rog-control-center = {
    enable = true;
    autoStart = true;
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
    no_logind = false;
    logout_timeout_s = 180;
    hotplug_type = "None";
  };


  boot.kernelModules = [
    "asus_nb_wmi"
    "asus_wmi"
    "bbswitch"
  ];
}
