{ pkgs, ... }:
{
  # Fonts
  fonts = {
    fontconfig.enable = true;
    enableDefaultPackages = false;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      noto-fonts
      noto-fonts-cjk-compact
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
      "Noto Sans CJK SC"
      "DejaVu Sans"
    ];
    serif = [
      "Noto Serif"
      "Noto Serif CJK SC"
      "DejaVu Serif"
    ];
  };
}
