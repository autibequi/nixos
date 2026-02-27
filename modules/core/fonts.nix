{ pkgs, ... }:
{
  # Fonts
  fonts = {
    fontconfig.enable = true;
    enableDefaultPackages = true;
    packages = with pkgs; [
      # General Fonts
      corefonts

      # Monospace fonts
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      fira-code
      jetbrains-mono
      meslo-lgs-nf # Font for p10k theme

      # Noto fonts
      noto-fonts
      noto-fonts-color-emoji

      # CJK Fonts
      # source-han-serif
      # source-han-sans
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      wqy_zenhei
      wqy_microhei
    ];
  };

  fonts.fontconfig.useEmbeddedBitmaps = true;

  fonts.fontconfig.subpixel.rgba = "rgb";

  fonts.fontconfig.defaultFonts = {
    monospace = [
      "MesloLGS NF"
      "JetBrainsMono Nerd Font"
      "FiraCode Nerd Font"
    ];
    sansSerif = [
      "Noto Sans"
      "Source Han Sans SC"
      "Source Han Sans TC"
      "Source Han Sans JP"
      "DejaVu Sans"
      "Noto Sans CJK SC"
    ];
    serif = [
      "Noto Serif"
      "Source Han Serif SC"
      "Source Han Serif TC"
      "Source Han Serif JP"
      "DejaVu Serif"
      "Noto Serif CJK SC"
    ];
  };
}
