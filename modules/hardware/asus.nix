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

  # asusd upstream tem ExecStartPre=sleep 1 (+1.1s no boot).
  # Reduzir para 0.2s — hid_asus já está pronto quando udev termina.
  systemd.services.asusd.serviceConfig.ExecStartPre = [
    ""  # limpa o ExecStartPre original (sleep 1)
    "/run/current-system/sw/bin/sleep 0.2"
  ];


  # asus_nb_wmi e asus_wmi são carregados automaticamente pelo udev
  # quando o hardware é detectado — forçar aqui só atrasava
  # systemd-modules-load (~1.7s no critical chain).
  # boot.kernelModules = [ "asus_nb_wmi" "asus_wmi" ];
}
