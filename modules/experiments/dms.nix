{ ... }:
{
  programs.dank-material-shell = {
    enable = true;

    systemd = {
      enable = true;
      restartIfChanged = true;
    };

    enableSystemMonitoring = true;
    enableDynamicTheming = true;   # wallpaper → tema via matugen
    enableAudioWavelength = true;  # visualizador cava
    enableClipboardPaste = true;   # histórico de clipboard (wtype)
  };
}
