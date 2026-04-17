{ pkgs, ... }:
{

  environment.systemPackages = with pkgs; [
    # Gnome Stuff
    desktop-file-utils
    gnome-extension-manager # Ferramenta para gerenciar extensões

    # Utils
    gnome-tweaks
    gnome-power-manager
  ];

  environment.gnome.excludePackages = with pkgs; [
    gnome-terminal
    epiphany
    gedit
    totem
    yelp
    geary
    gnome-calendar
    gnome-contacts
    gnome-music
    gnome-photos
    gnome-tour
    evince
    gnome-clocks
    gnome-characters
    gnome-sound-recorder
    gnome-logs
    gnome-usage
    simple-scan
    gnome-connections
    gnome-text-editor
    gnome-font-viewer
  ];
}
