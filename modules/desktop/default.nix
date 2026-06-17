{ ... }:
{
  # Desktop: compositor Wayland (Hyprland + ecossistema) e greeter de login.
  imports = [
    ./hyprland
    ./greetd.nix
  ];
}
