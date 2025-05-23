{ config, pkgs, ... }:

{
  services.flatpak.enable = true;

  # # Flatpak packages to install
  # services.flatpak.packages = [
  #   "com.github.tenderowl.frog"
  #   "io.github.kelvinnovais.Kasasa"
  # ];
}