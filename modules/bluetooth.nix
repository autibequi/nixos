{ config, pkgs, ... }:

{
  # Habilitar Bluetooth com configurações avançadas
  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluez5-experimental; # Versão experimental com mais recursos
    powerOnBoot = true; # Liga o Bluetooth automaticamente na inicialização
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
        FastConnectable = true;
        JustWorksRepairing = "always";
        MultiProfile = "off";
        AutoEnable = true;
      };
    };
  };

  services.pipewire = {
    enable = true;
    jack.enable = true;
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