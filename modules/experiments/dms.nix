{ unstable, ... }:
{
  programs.dank-material-shell = {
    enable = true;

    # dgop só existe no unstable, não no stable 25.11
    dgop.package = unstable.dgop;

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
