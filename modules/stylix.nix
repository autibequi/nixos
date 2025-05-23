{ config, pkgs, lib, ... }:

{
  stylix = {
    # Toggle because easier
    enable = false;
    autoEnable = false;


    targets.plymouth.enable = false;
    cursor = {
      package = pkgs.banana-cursor;
      name = "banana";
      size = 40;
    };
    base16Scheme = "${pkgs.base16-schemes}/share/themes/dracula.yaml";
    fonts = {
      serif = {
        package = pkgs.noto-fonts-cjk-serif;
        name = "Noto Serif CJK TC";
      };
      sansSerif = {
        package = pkgs.noto-fonts;
        name = "Noto Sans";
      };
      monospace = {
        package = pkgs.nerd-fonts.fira-code;
        name = "FiraCode Nerd Font Mono";
      };
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
    };
  };
}