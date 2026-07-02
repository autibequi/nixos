{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "nmsurf";
  version = "1.0.3";

  src = fetchFromGitHub {
    owner = "aayushkdev";
    repo = "nmsurf";
    rev = "v${version}";
    hash = "sha256-ARB8QGbfUcGf2/oemrPulWfIsou9cK1h9oMSZC5YW5k=";
  };

  vendorHash = "sha256-2U9hBA+q3nW4YO47PN+eorBLq0z4kj2zCZ6q7wD75PQ=";

  meta = with lib; {
    description = "Fast, minimal NetworkManager frontend for Wofi/Walker/Rofi/Fuzzel";
    homepage = "https://github.com/aayushkdev/nmsurf";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
