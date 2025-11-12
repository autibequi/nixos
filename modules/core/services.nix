{
  ...
}:

{
  # sunshine
  services.sunshine.enable = true;
  # TODO: add steam later
  # services.sunshine.applications.apps = [

  # ];

  # Disable Evil Printer
  services.printing.enable = false;

  # Preload common apps for snappier experience
  # services.preload.enable = true;

  # fwupd
  services.fwupd.enable = true;
}
