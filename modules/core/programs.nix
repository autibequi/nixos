{ pkgs, ... }:

{
  # Programs
  programs = {
    adb.enable = true;
    direnv.enable = true;
    starship.enable = true;
    starship.transientPrompt.enable = true;
  };

  # Waydroid
  virtualisation.waydroid.enable = true;
  
  environment.systemPackages = with pkgs; [
    python3Packages.pyclip
    wl-clipboard-rs
    waydroid-helper
  ];
}
