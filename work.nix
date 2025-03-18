{ config, pkgs, lib, ... } :
{

      # Environment Variables
    environment.sessionVariables = {
        CGO_ENABLED=1; # kafka
    };

    # Systemd Packages
    systemd.packages = with pkgs; [ cloudflare-warp ];

    environment.systemPackages = with pkgs; [
        # Tools
        dbeaver-bin
        insomnia
        podman
        postgresql
        terraform

        # clitools
        dig
        awscli2
        k9s # kubernets cli
        kubectl

        # vpn
        openvpn
        cloudflare-warp

        # editors
        vscode
        
        # python
        python312
        python312Packages.magic
        poetry
        pyenv
        file # libmagic - intraupload

        # Node
        nodejs
        nodePackages.eslint

        # Flutter
        flutter
        android-studio
        android-tools
        gradle
        dart

        # golang
        go
        graphviz #golang pprof
        gcc # kafka go

        # video stuff
        ffmpeg
        vlc

        # TESTING:
        github-copilot-cli
        devbox
    ];

    # TESTING: Dynamic Libraries
    environment.variables = {
        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
            pkgs.file
        ];
    };
    
    # Gambiarra pra rodar as coisas do jeito não nix
    # mostly vscode extensions.
    programs.nix-ld.enable = true;
    programs.nix-ld.package = pkgs.nix-ld-rs;

    # Services
    programs.openvpn3.enable = true;
}