{ pkgs, ... }:
{
  # Wiki: 
  # https://nixos.wiki/wiki/Steam

  # Adiciona MangoHud e MangoJuice para overlay e monitoramento em jogos Steam
  environment.systemPackages = with pkgs; [
    mangohud
    mangojuice
  ];

  programs = {
    gamescope = {
      enable = true;
      capSysNice = true;
    };
    steam = {
      enable = true;
      gamescopeSession.enable = true;

      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    };
  };

  # Java support for Steam
  programs.java.enable = true; 

  # Enable Xbox controller support
  # hardware.xone.enable = true; 

  # Enable AppImage support
  # programs.appimage.enable = true;
  # programs.appimage.binfmt = true;
}
