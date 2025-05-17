{ pkgs, ... }:

{
  # Cursor themes for aesthetics
  environment.systemPackages = with pkgs; [
    banana-cursor
    apple-cursor
    bibata-cursors
    oreo-cursors-plus
  ];
}