{ ... }:

let
  nix-alien-pkgs = import (
    builtins.fetchTarball {
      url = "https://github.com/thiagokokada/nix-alien/tarball/master";
      sha256 = "06556zv02v5phjf4byybf4lk28srwcmkz1qikyv1590i8bv26v33";
    }
    
  ) { };
in
{
  environment.systemPackages = with nix-alien-pkgs; [
    nix-alien
  ];

  # Optional, but this is needed for `nix-alien-ld` command
  programs.nix-ld.enable = true;
}