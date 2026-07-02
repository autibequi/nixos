{ lib, ... }:
{
  # Versão de estado do sistema — fixa o schema de dados stateful.
  # NÃO alterar sem ler as release notes do NixOS correspondentes.
  system.stateVersion = "25.05";

  # are we ARM yet?
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # python3.12-doc build quebrado em nixpkgs 26.05 (docutils 0.22 regression).
  # documentation.doc coleta o output `doc` de todos os systemPackages —
  # desabilitado até nixpkgs corrigir o build do python312.
  documentation.doc.enable = false;

  # /tmp em RAM — com 46GB+ RAM é gratuito e acelera builds/temp
  boot.tmp.useTmpfs = true;
  boot.tmp.tmpfsSize = "8G";

  # Add local bin to PATH
  environment.localBinInPath = true;

  environment.variables.EDITOR = "zed --wait";
  environment.variables.VISUAL = "zed --wait";

  # Variáveis de sessão — Wayland pains
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    OZONE_PLATFORM = "wayland";
    # ELECTRON_OZONE_PLATFORM_HINT — definido como "auto" em hyprland.conf (via UWSM env)
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    # Qt6 Wayland backend — sem isso Qt6 apps (ex: hyprpolkitagent) não conseguem
    # carregar nenhum QPA e crasham com SIGABRT em init_platform(), derrubando a sessão.
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    # GTK/WebKitGTK (Yaak Tauri, etc): sem isso alguns AppImages caem em XWayland
    # silenciosamente e renderizam em 1x esticado pelo compositor (pixelado em scale 2.0).
    # "wayland,x11" = tenta wayland primeiro, cai pra x11 só se não tiver Wayland disponível.
    GDK_BACKEND = "wayland,x11";
  };
}
