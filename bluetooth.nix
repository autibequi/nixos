{ config, pkgs, ... }:

{
  # Enable Bluetooth and required codecs
  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluez5;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;  # Enable experimental features
      };
    };
  };

  # PipeWire configuration
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Environment variables for Bluetooth optimization
  environment.sessionVariables = {
    PIPEWIRE_RATE = "44100";
    PIPEWIRE_QUANTUM = "512/44100";
    PIPEWIRE_LATENCY = "512/44100";
  };

  # Additional packages for codec support
  environment.systemPackages = with pkgs; [
    ldacbt
    libfreeaptx
  ];

  # Kernel parameters for better Bluetooth performance
  boot.kernelParams = [
    "btusb.enable_autosuspend=n"
    "btusb.enable_autosuspend_for_controller=n"
  ];

  # Disable Bluetooth autosuspend
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="bluetooth", ATTR{power/control}="on"
  '';
}