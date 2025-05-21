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
        # Melhorar a qualidade de áudio e estabilidade da conexão
        FastConnectable = true;
        JustWorksRepairing = "always";
        MultiProfile = "multiple";
        AutoEnable = true;
      };
    };
  };

  # Configuração PipeWire otimizada
  services.pipewire = {
    enable = true;
    jack.enable = true; # Adicionar suporte JACK para aplicativos profissionais
    
    # Configuração avançada para Bluetooth
    wireplumber.extraConfig."10-bluez" = {
      "monitor.bluez.properties" = {
        "bluez5.roles" = [
          "hfp_hf"
          "hfp_ag"
          "a2dp_sink"
          "a2dp_source"
          "bap_sink"
          "bap_source"
          "hsp_hs"
          "hsp_ag"
        ];
        "bluez5.auto-connect" = [ "a2dp_sink" "hfp_ag" ];
        "bluez5.codecs" = [ "sbc_xq" "aac" "ldac" "aptx" "aptx_hd" "faststream" ];
      };
    };
    
    wireplumber.extraConfig."11-bluetooth-policy" = {
      "wireplumber.settings" = {
        "bluetooth.autoswitch-to-headset-profile" = true;
        "bluetooth.hfphsp-backend" = "native";
      };
    };
  };


  # Pacotes adicionais para suporte a codecs
  environment.systemPackages = with pkgs; [
    ldacbt
    libfreeaptx
    sbc
    fdk-aac 
    bluez-tools 
    pavucontrol
    helvum 
  ];
}