{ pkgs, ... }:
{
  # Fonts
  fonts = {
    fontconfig.enable = true;
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
    ];
  };

  fonts.fontconfig.defaultFonts = {
    monospace = [
      "FiraCode Nerd Font"
    ];
    sansSerif = [
      "JetBrainsMono Nerd Font"
    ];
    serif = [
      "FiraCode Nerd Font"
    ];
  };
}
