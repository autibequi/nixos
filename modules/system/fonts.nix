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
      maple-mono.NF # fonte principal — Nerd Font, arredondada, x-height alto
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.iosevka
      nerd-fonts.caskaydia-cove
      fira-code
      jetbrains-mono
      meslo-lgs-nf # Font for p10k theme

      # Noto fonts
      noto-fonts
      noto-fonts-color-emoji

      # CJK (mínimo para fallback de caracteres)
      noto-fonts-cjk-sans
    ];
  };

  fonts.fontconfig.useEmbeddedBitmaps = true;

  fonts.fontconfig.subpixel.rgba = "rgb";

  fonts.fontconfig.defaultFonts = {
    monospace = [
      "Maple Mono NF"
      "JetBrainsMono Nerd Font"
      "MesloLGS NF"
      "FiraCode Nerd Font"
    ];
    sansSerif = [
      "Noto Sans"
      "DejaVu Sans"
      "Noto Sans CJK SC"
    ];
    serif = [
      "Noto Serif"
      "DejaVu Serif"
    ];
  };
}
