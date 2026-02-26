{ pkgs, lib, ... }:
{
  boot = {
    plymouth = {
      enable = true;
      theme = lib.mkDefault "dragon"; # Define "dragon" como padrão
      themePackages = with pkgs; [
        # By default we would install all themes
        # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/pkgs/by-name/ad/adi1090x-plymouth-themes/shas.nix
        (adi1090x-plymouth-themes.override {
          selected_themes = [ "dragon" ];
        })
      ];
    };

    loader.timeout = 0;

    # Silencia completamente os logs do kernel no console
    consoleLogLevel = 0;

    # Desativa mensagens verbosas do initrd
    initrd.verbose = false;

    kernelParams = [
      # Boot silencioso
      "quiet"
      "splash"
      "loglevel=0"

      # Suprime completamente logs do udev/systemd no console
      "udev.log_priority=3"
      "rd.udev.log_priority=3"

      # Desativa o cursor piscante que aparece antes do Plymouth
      "vt.global_cursor_default=0"

      # Suprime mensagens do Plymouth antes do DRM estar pronto
      "plymouth.use-simpledrm=1"

      # Desativa BGRT (logo OEM da BIOS que pode vazar)
      "bgrt_disable"
    ];
  };

  # Garantir que o Plymouth receba o sinal de quit corretamente
  # antes do greeter aparecer, evitando flicker de terminal
  systemd.services."plymouth-quit" = {
    before = [ "greetd.service" ];
  };
}
