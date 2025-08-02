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
    ./core/hibernate.nix

    # Stable Modules
    ./modules/bluetooth.nix
    ./modules/plymouth.nix
    ./modules/ai.nix
    ./modules/steam.nix
    ./modules/podman.nix

    # Custom Modules
    ./modules/flatpak.nix
  ];
}
