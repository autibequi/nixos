{
  # Wiki: 
  # https://nixos.wiki/wiki/Steam

  environment.variables = {
    # This forces Steam and other GTK apps to scale by a factor of 2 (200%)
    GDK_SCALE = "1.6";
  };

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

  # Enable Xbox controller support
  # hardware.xone.enable = true; 

  # Enable AppImage support
  # programs.appimage.enable = true;
  # programs.appimage.binfmt = true;
}