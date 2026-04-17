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

    # loader.timeout já definido em core.nix
    # consoleLogLevel, quiet, loglevel, udev.log_priority, vt.global_cursor_default,
    # bgrt_disable já definidos em kernel.nix — evitar duplicação

    kernelParams = [
      "splash"
      "plymouth.use-simpledrm=1"
    ];
  };

  # Garantir que o Plymouth receba o sinal de quit corretamente
  # antes do greeter aparecer, evitando flicker de terminal
  systemd.services."plymouth-quit" = {
    before = [ "greetd.service" ];
  };
}
