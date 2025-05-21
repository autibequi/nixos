{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Extensions
    # Productivity Extensions
    gnomeExtensions.caffeine
    gnomeExtensions.pano
    gnomeExtensions.gsconnect
    gnomeExtensions.night-theme-switcher
    gnomeExtensions.quick-settings-audio-panel
    gnomeExtensions.auto-power-profile

    # Window Management Extensions
    gnomeExtensions.tiling-shell
    gnomeExtensions.window-gestures
    gnomeExtensions.wtmb-window-thumbnails

    # Visual and UI Enhancements
    gnomeExtensions.blur-my-shell
    gnomeExtensions.burn-my-windows
    gnomeExtensions.hide-cursor
    gnomeExtensions.emoji-copy
    gnomeExtensions.open-bar
    gnomeExtensions.window-desaturation

    # System and Utility Extensions
    gnomeExtensions.vitals
    gnomeExtensions.media-controls
    gnomeExtensions.appindicator
    gnomeExtensions.fuzzy-app-search
    gnomeExtensions.gnome-40-ui-improvements
    gnomeExtensions.advanced-alttab-window-switcher
    gnomeExtensions.custom-command-toggle
    gnomeExtensions.upower-battery

    # super cool but nukes battery life due to GPU usage on idle
    # gnomeExtensions.mouse-tail
    # gnomeExtensions.wiggle
  ];

  # Config Moving
  home-manager.users."pedrinho" = { pkgs, lib, ... }:
  {
    home.file."~/.config/gnome-shell/extensions/burn-my-windows/profiles/pedrinho.profile.conf".source = ./extensions-configs/burn-my-windows.conf;
    home.file."~/toggle.ini".source = ./extensions-configs/custom-toggle.conf;
  };
}