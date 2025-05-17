{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Extensions
    # Productivity Extensions
    gnomeExtensions.caffeine
    gnomeExtensions.pano
    gnomeExtensions.gsconnect
    gnomeExtensions.auto-power-profile
    gnomeExtensions.night-theme-switcher
    gnomeExtensions.quick-settings-audio-panel

    # Battery and Power Extensions
    gnomeExtensions.battery-time
    gnomeExtensions.upower-battery

    # Window Management Extensions
    gnomeExtensions.tiling-shell
    gnomeExtensions.window-gestures
    gnomeExtensions.wtmb-window-thumbnails

    # Visual and UI Enhancements
    gnomeExtensions.blur-my-shell
    gnomeExtensions.burn-my-windows
    gnomeExtensions.mouse-tail
    gnomeExtensions.wiggle
    gnomeExtensions.hide-cursor
    gnomeExtensions.emoji-copy
    gnomeExtensions.open-bar
    gnomeExtensions.window-desaturation

    # System and Utility Extensions
    gnomeExtensions.vitals
    gnomeExtensions.media-controls
    gnomeExtensions.appindicator
    gnomeExtensions.restart-to
    gnomeExtensions.fuzzy-app-search
    gnomeExtensions.gnome-40-ui-improvements
    gnomeExtensions.advanced-alttab-window-switcher
    gnomeExtensions.custom-command-toggle
  ];

  # Config Moving
  home-manager.users."pedrinho" = { pkgs, lib, ... }:
  {
    home.file."~/.config/gnome-shell/extensions/burn-my-windows/profiles/1747253129691946.conf".source = ./extensions-configs/burn-my-windows.conf;
    home.file."~/toggle.ini".source = ./extensions-configs/custom-toggle.conf;
  };
}