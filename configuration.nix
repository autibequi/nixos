{
  ...
}:
{
  # Importa Setup do Usuario
  imports = [
    # Hardware Configurations
    ./hardware.nix

    # Core Modules
    ./core/nix.nix
    ./core/hardware.nix
    ./core/core.nix
    ./core/home.nix
    ./core/services.nix
    ./core/programs.nix
    ./core/packages.nix
    ./core/fonts.nix
    ./core/shell.nix
    ./core/kernel.nix

    # Stable Modules
    ./modules/bluetooth.nix
    ./modules/plymouth.nix
    ./modules/ai.nix
    ./modules/hibernate.nix
    ./modules/steam.nix
    ./modules/podman.nix

    # Laptop Modules
    ./modules/tlp.nix
    ./modules/battery.nix

    # Hardware
    ./modules/asus.nix
    # ./modules/nvidia.nix

    # Desktop Enviroments
    ./modules/hyprland/core.nix
    # ./modules/gnome/core.nix
    # ./modules/cosmic.nix
    # ./modules/kde.nixs

    # Custom Modules (Packages not well supported yet by nixpkgs)
    ./modules/custom/flatpak.nix
    # ./modules/custom/howdy.nix

    # Other Modules
    # ./modules/work.nix
  ];
}
