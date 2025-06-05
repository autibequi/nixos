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
    code-cursor
    cartero
    insomnia

    # --- Python ---
    python312
    pipx
    poetry
    pyenv
    file # libmagic - intraupload

    # --- JS, ick! ---
    nodejs
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

  ];

  # TESTING: Dynamic Libraries
  # environment.variables = {
  #     LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
  #         pkgs.file
  #     ];
  # };

  # Gambiarra pra rodar as coisas do jeito não nix
  # mostly vscode extensions.
  programs.nix-ld.enable = true;
  programs.nix-ld.package = pkgs.nix-ld-rs;

  # Services
  programs.openvpn3.enable = true;

  networking.extraHosts = ''
    127.0.0.1 local.estrategia-sandbox.com.br
    127.0.0.1 concursos.local.estrategia.com
    127.0.0.1 oab.local.estrategia.com
    127.0.0.1 carreiras-juridicas.local.estrategia.com
  '';

  # Cloudflare Warp
  services.cloudflare-warp.enable = true;

  # TODO: check if fixed
  # creates a custom systemd service for the warp taskbar since it stopped working
  systemd.user.services.warp-taskbar-custom = {
    description = "Cloudflare Zero Trust Client Taskbar";
    requires = [ "dbus.socket" ];
    after = [ "dbus.socket" ];
    bindsTo = [ "graphical-session.target" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.cloudflare-warp}/bin/warp-taskbar";
      Restart = "always";
      BindReadOnlyPaths = "${pkgs.cloudflare-warp}:/usr:";
    };
  };

  home-manager.users."pedrinho" =
    { ... }:
    {
      programs.git = {
        enable = true;
        userName = "Pedro Correa";
        userEmail = "pedro.correa@estrategia.com";
      };
    };
}
