{ ... }:
{
  # Habilitar Bluetooth com configurações avançadas
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true; # Liga o Bluetooth automaticamente na inicialização
    settings = {
      General = {
        Enable = "Media,Socket";
        Experimental = true;
        FastConnectable = true;
        JustWorksRepairing = "always";
        MultiProfile = "on";
        AutoEnable = true;
        AutoConnect = true;
        ReconnectAttempts = 5;
      };
    };
  };

  services.pipewire = {
    enable = true;
    jack.enable = true;
    alsa.enable = true;
    wireplumber.enable = true;
  };
}
