{ config, pkgs, ... }:

{
  services.xserver = {
    enable = true;
    layout = "us";
    xkbOptions = "eurosign:e";
    
    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;
  };

  hardware.pulseaudio.enable = true;

  environment.systemPackages = with pkgs; [
    konsole
    dolphin
    kate
  ];
}