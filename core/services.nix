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

  # Preload common apps for snappier experience
  services.preload.enable = true;

  # fwupd
  services.fwupd.enable = true;

  # docker
  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
}
