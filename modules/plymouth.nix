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
    consoleLogLevel = 0;
    initrd.verbose = false;
    kernelParams = [
      "plymouth.use-simpledrm=1"
      "udev.log_priority=3"
      "loglevel=3"
      "quiet"
      "splash"
    ];
  };
}
