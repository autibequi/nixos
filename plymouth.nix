{ pkgs, ... }: {
  boot = {
    plymouth = {
      enable = true;
      theme = "dragon";
      themePackages = with pkgs; [
        # By default we would install all themes
        # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/pkgs/by-name/ad/adi1090x-plymouth-themes/shas.nix
        (adi1090x-plymouth-themes.override {
          selected_themes = [ "abstract_ring_alt" "dragon" "connect" ];
        })
      ];
    };

    # Enable "Silent boot"
    consoleLogLevel = 3;
    loader.timeout = 0;
  };
}
