{ pkgs, ... }:

{
  # Programs
  programs = {
    adb.enable = true;
    direnv.enable = true;
    starship.enable = true;
    starship.transientPrompt.enable = true;

    neovim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;
      viAlias = true;
    };

    firefox = {
      enable = true;
    };
  };

  # Waydroid
  virtualisation.waydroid.enable = true;
  
  environment.systemPackages = with pkgs; [
    python3Packages.pyclip
    wl-clipboard-rs
    waydroid-helper
  ];
}
