{ ... }:
{
  # Apps: ambientes de aplicação específicos.
  imports = [
    ./work.nix # toolchain Estratégia (Go/Node/Flutter/Python, VPN, hosts locais)
    ./zed.nix  # Zed Editor (binário oficial pré-compilado, sem build)
    ./yaak.nix # Yaak API client (AppImage oficial wrappado)
  ];
}
