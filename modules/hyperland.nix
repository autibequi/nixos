
{ inputs, pkgs, ... }:

{
  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Hyprland window manager and related tools
  environment.systemPackages = with pkgs; [
    hyprpaper
    xdg-desktop-portal-hyprland
    inputs.caelestia-shell.packages.x86_64-linux.default
  ];

  # Enable PipeWire for audio
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Copy the hyprland config
  environment.etc."hypr/hyprland.conf".source = ../dotfiles/hyprland.conf;
}
