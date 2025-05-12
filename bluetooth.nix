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
      Policy = {
        AutoEnable = true;
      };
    };
  };

  # Habilitar serviço blueman para interface gráfica
  services.blueman.enable = true;

  # Configuração PipeWire otimizada
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true; # Adicionar suporte JACK para aplicativos profissionais
    wireplumber.enable = true;
    
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
        "bluez5.msbc-support" = true;
        "bluez5.sbc-xq-support" = true;
      };
    };
    
    wireplumber.extraConfig."11-bluetooth-policy" = {
      "wireplumber.settings" = {
        "bluetooth.autoswitch-to-headset-profile" = true;
        "bluetooth.hfphsp-backend" = "native";
      };
    };
  };

  # Variáveis de ambiente otimizadas para áudio Bluetooth
  environment.sessionVariables = {
    PIPEWIRE_RATE = "48000"; # Taxa de amostragem mais alta para melhor qualidade
    PIPEWIRE_QUANTUM = "256/48000"; # Latência reduzida
    PIPEWIRE_LATENCY = "256/48000"; # Latência reduzida
    PIPEWIRE_LINK_PASSIVE = "true"; # Melhora a estabilidade
  };

  # Pacotes adicionais para suporte a codecs
  environment.systemPackages = with pkgs; [
    ldacbt
    libfreeaptx
    sbc
    bluez-tools # Ferramentas adicionais para diagnóstico
    bluez-alsa # Suporte ALSA para Bluetooth
  ];

  # Parâmetros do kernel para melhor desempenho Bluetooth
  boot.kernelParams = [
    "btusb.enable_autosuspend=n"
    "btusb.enable_autosuspend_for_controller=n"
    "bluetooth.disable_ertm=1" # Desativa ERTM para melhor compatibilidade
  ];

  # Desativar autosuspend do Bluetooth e configurações adicionais
  services.udev.extraRules = ''
    # Manter dispositivos Bluetooth sempre ligados
    ACTION=="add", SUBSYSTEM=="bluetooth", ATTR{power/control}="on"
    
    # Prioridade para dispositivos Bluetooth USB
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="*", ATTRS{idProduct}=="*", TAG+="uaccess", TAG+="udev-acl"
    
    # Reiniciar controladores Bluetooth problemáticos
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="0cf3", ATTRS{idProduct}=="*", RUN+="${pkgs.kmod}/bin/modprobe -r btusb", RUN+="${pkgs.kmod}/bin/modprobe btusb"
  '';

  # Habilitar serviço de reinicialização automática do Bluetooth em caso de falha
  systemd.services.bluetooth-restart = {
    description = "Reiniciar serviço Bluetooth em caso de falha";
    after = [ "bluetooth.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'systemctl --no-block restart bluetooth.service'";
    };
  };
}