{ pkgs, ... }:
{

  # Environment Variables
  environment.sessionVariables = {
    CGO_ENABLED = 1; # kafka
    GOPRIVATE = "github.com/estrategiahq/*";
  };

  # Systemd Packages
  environment.systemPackages = with pkgs; [
    # --- Testing ---
    gh-copilot

    # --- CLI ---
    dig
    awscli2
    k9s # kubernets frontend
    kubectl
    devbox
    terraform
    postgresql # for dbeaver dumps
    ffmpeg # video stuff
    openvpn # bastion access

    # --- APPS  ---
    dbeaver-bin
    chromium # work browser
    vscode
    cartero
    insomnia

    # --- Python ---
    python312
    pipx
    poetry
    pyenv
    file # libmagic - intraupload

    # --- JS, ick! ---
    nodejs_24
    nodePackages.eslint

    # --- Flutter ---
    flutter
    android-studio
    android-tools
    gradle
    dart

    # --- Golang ---
    go
    delve
    graphviz
    gcc # because kafka fsr

    # --- Warp ---
    wgcf

    jetbrains.datagrip
  ];

  # TESTING: Dynamic Libraries
  # environment.variables = {
  #     LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
  #         pkgs.file
  #     ];
  # };

  # Services
  programs.openvpn3.enable = true;

  networking.extraHosts = ''
    127.0.0.1 local.estrategia-sandbox.com.br
    127.0.0.1 concursos.local.estrategia.com
    127.0.0.1 oab.local.estrategia.com
    127.0.0.1 carreiras-juridicas.local.estrategia.com

    127.0.0.1 redis
  '';

  # Cloudflare Warp
  services.cloudflare-warp.enable = true;
}
