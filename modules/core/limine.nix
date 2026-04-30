{ pkgs, ... }:
{
  boot.loader.limine.enable = true;
  boot.loader.limine.efiSupport = true;
  boot.loader.limine.maxGenerations = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 3; # segundos antes de auto-boot (0 = imediato, sem menu)

  # Windows está em nvme0n1p1 (GPT partition 1) — ESP separado do NixOS (p4)
  boot.loader.limine.extraEntries = ''
    /Windows 11
      protocol: chainload
      path: boot(0,gpt1):///EFI/Microsoft/Boot/bootmgfw.efi
  '';

  # Tema CachyOS — splash oficial + paleta Catppuccin Mocha
  boot.loader.limine.style = {
    wallpapers = [
      (pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/CachyOS/cachyos-wallpapers/develop/usr/share/wallpapers/cachyos-wallpapers/limine-splash.png";
        sha256 = "1pq2hlbrhjyya8wp92alf73xi5hjh7yfnyxk576rf8lvfbwhjbzr";
      })
    ];
    wallpaperStyle = "stretched";
    graphicalTerminal = {
      foreground = "cdd6f4";
      background = "801e1e2e"; # TTRRGGBB — 80 = ~50% transparente sobre o wallpaper
      brightForeground = "cdd6f4";
      brightBackground = "801e1e2e";
      palette = "45475a;f38ba8;a6e3a1;f9e2af;89b4fa;cba4f7;89dceb;bac2de";
      brightPalette = "585b70;f38ba8;a6e3a1;f9e2af;89b4fa;cba4f7;89dceb;cdd6f4";
      margin = 10;
      marginGradient = 4;
    };
    interface = {
      brandingColor = 5; # mauve — cor 5 da palette acima (cba4f7)
    };
  };
}
