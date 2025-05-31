{
  ...
}:

{
  # Disable Evil Printer
  services.printing.enable = false;

  # logitech drivers
  services.solaar.enable = true;

  # flatpak
  services.flatpak.enable = true;

  # Enable Podman
  virtualisation.podman.enable = true;
  virtualisation.podman.dockerCompat = true;
  virtualisation.podman.defaultNetwork.settings.dns_enabled = true;

  # Preload common apps for snappier experience
  services.preload.enable = true;
}
