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
      "Noto Color Emoji"
      "FiraCode Nerd Font"
    ];
    sansSerif = [
      "JetBrainsMono Nerd Font"
      "Noto Color Emoji"
      "FiraCode Nerd Font"
    ];
    serif = [
      "JetBrainsMono Nerd Font"
      "Noto Color Emoji"
      "FiraCode Nerd Font"
    ];
  };
}
