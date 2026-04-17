# Ly — greeter TUI (https://github.com/fairyglade/ly)
#
# Rollback para tuigreet via greetd:
#   1. Em configuration.nix: comente ./modules/core/ly.nix e descomente ./modules/core/greetd.nix
#   2. Em greetd.nix: descomente o bloco services.greetd
#
{ config, lib, pkgs, ... }:
{
  # Evita conflito se greetd.nix voltar a ser importado sem limpar este módulo
  services.greetd.enable = lib.mkForce false;

  services.displayManager.ly = {
    enable = true;
    # Wayland-only: desliga suporte X11 no Ly (opcional, reduz dependências)
    # x11Support = false;

    settings = {
      # Ajuste a mensagem ao gosto; Ly usa config.ini (merge com defaults do nixpkgs)
      # animation = "doom";
    };
  };
}
