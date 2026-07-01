{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "nmsurf";
  version = "1.0.3";

  src = fetchFromGitHub {
    owner = "aayushkdev";
    repo = "nmsurf";
    rev = "v${version}";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

  meta = with lib; {
    description = "Fast, minimal NetworkManager frontend for Wofi/Walker/Rofi/Fuzzel";
    homepage = "https://github.com/aayushkdev/nmsurf";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
