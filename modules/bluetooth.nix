{ pkgs, ... }:

{
  # Habilitar Bluetooth com configurações avançadas
  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluez5-experimental; # Versão experimental com mais recursos
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
        LogLevel = "debug";
      };
    };
  };

  services.pipewire = {
    enable = true;
    jack.enable = true;
    alsa.enable = true;
    wireplumber.enable = true;
  };

  # Pacotes adicionais para suporte a codecs
  environment.systemPackages = with pkgs; [
    ldacbt
    libfreeaptx
    sbc
    bluez-tools
    pavucontrol
    helvum
  ];
}
