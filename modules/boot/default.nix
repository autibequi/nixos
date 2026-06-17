{ ... }:
{
  # Boot: bootloader, kernel + tuning low-level, splash, suspend/hibernate.
  imports = [
    ./bootloader.nix
    ./kernel.nix
    ./plymouth.nix
    ./hibernate.nix
  ];
}
