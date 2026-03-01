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
    ./modules/logiops.nix
    ./modules/bluetooth.nix
    ./modules/plymouth.nix # Its so fast now that its not needed :(
    ./modules/ai.nix
    ./modules/steam.nix
    ./modules/podman.nix

    # Hardware Specific
    ./modules/asus.nix
    ./modules/nvidia.nix

    # Desktop Enviroments
    ./modules/hyprland.nix
    # ./modules/gnome/core.nix
    # ./modules/cosmic.nix
    # ./modules/kde.nixs

    # Other Modules
    ./modules/work.nix
    ./modules/virt.nix
    # ./modules/tlp.nix
    # ./modules/docker.nix
    # ./modules/flatpak.nix
  ];
}
