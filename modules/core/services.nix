{
  ...
}:

{
  # sunshine
  # services.sunshine.enable = true;
  # TODO: add steam later
  # services.sunshine.applications.apps = [

  # ];

  # Disable Evil Printer
  services.printing.enable = false;

  # Preload common apps for snappier experience
  # services.preload.enable = true;

  # fwupd
  services.fwupd.enable = true;

  # NetworkManager-wait-online blocks the entire critical chain for ~3s.
  # Nothing on this machine actually needs the network to be fully online
  # before graphical.target: docker uses socket activation, libvirt only
  # needs the daemon socket, and user apps connect on-demand.
  systemd.services.NetworkManager-wait-online.enable = false;
}
