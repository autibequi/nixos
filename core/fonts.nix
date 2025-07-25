{ pkgs, ... }:
{
  # Fonts
  fonts = {
    fontconfig.enable = true;
    enableDefaultPackages = false;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      noto-fonts-emoji
    ];
  };

  fonts.fontconfig.useEmbeddedBitmaps = true;

  fonts.fontconfig.defaultFonts = {
    monospace = [
      "JetBrainsMono Nerd Font"
      "FiraCode Nerd Font"
    ];
    sansSerif = [
      "Noto Sans"
      "DejaVu Sans"
    ];
    serif = [
      "Noto Serif"
      "DejaVu Serif"
    ];
  };
}
