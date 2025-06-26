{
  ...
}:
{
  # System State Version
  system.stateVersion = "25.05";

  imports = [
    # Core
    ./core/nix.nix
    ./core/core.nix
    ./core/kernel.nix
    ./core/home.nix
    ./core/services.nix
    ./core/programs.nix
    ./core/packages.nix
    ./core/shell.nix
    ./core/fonts.nix

    # Extra
    ./modules/ai.nix
    ./modules/asus.nix
    ./modules/battery.nix
    ./modules/bluetooth.nix
    # ./modules/podman.nix
    ./modules/nvidia.nix
    ./modules/plymouth.nix
    # ./modules/howdy.nix
    # ./modules/flatpak.nix
    ./modules/work.nix

    # Desktop Environments
    ./modules/gnome/core.nix
    ./modules/cosmic.nix
    # ./modules/kde.nix
  ];
}
