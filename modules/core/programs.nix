{ pkgs, ... }:

{
  # Programs
  programs = {
    adb.enable = true;
    direnv.enable = true;
    starship.enable = true;
    starship.transientPrompt.enable = true;
  };

  # Waydroid: habilitado mas container NÃO sobe automaticamente no boot.
  # O waydroid-container.service consumia ~55MB de RAM e CPU em idle.
  # Para usar: `sudo systemctl start waydroid-container` ou `waydroid session start`
  virtualisation.waydroid.enable = true;
  systemd.services.waydroid-container.wantedBy = [ ]; # remove de multi-user.target

  environment.systemPackages = with pkgs; [
    python3Packages.pyclip
    wl-clipboard-rs
    waydroid-helper
  ];
}
