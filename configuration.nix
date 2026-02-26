{
  ...
}:
{
  # Importa Setup do Usuario
  imports = [
    # Hardware Configurations
    ./hardware.nix

    # Core Modules
    ./modules/core/nix.nix
    ./modules/core/core.nix
    ./modules/core/home.nix
    ./modules/core/services.nix
    ./modules/core/programs.nix
    ./modules/core/packages.nix
    ./modules/core/fonts.nix
    ./modules/core/shell.nix
    ./modules/core/kernel.nix
    ./modules/core/hibernate.nix

    # Greeter
    ./modules/greetd.nix

    # Stable Modules
    ./modules/bluetooth.nix
    ./modules/plymouth.nix
    ./modules/ai.nix
    ./modules/steam.nix
    # ./modules/podman.nix
    ./modules/docker.nix

    # Custom Modules
    ./modules/flatpak.nix
    ./modules/virt.nix
  ];
}
