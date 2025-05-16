{ config, pkgs, lib, ... } :
{

    # Environment Variables
    environment.sessionVariables = {
        CGO_ENABLED=1; # kafka
        GOPRIVATE="github.com/estrategiahq/*";
    };

    services = {
        cloudflare-warp.enable = true;
    };

    # Systemd Packages
    environment.systemPackages = with pkgs; [
        cloudflare-warp

        # Tools
        dbeaver-bin
        podman
        postgresql
        terraform

        # REST Clients
        cartero
        insomnia

        # clitools
        dig
        awscli2
        k9s # kubernets cli
        kubectl

        # vpn
        openvpn

        # editors
        vscode
        
        # python
        python312
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

        # TESTING:
        github-copilot-cli
        devbox
        code-cursor

        # asthetics?
        banana-cursor
        apple-cursor
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
    '';

    # TODO: check if fixed
    # Manually create the systemd service for warp taskbar (dunno why)
    systemd.services.warp-taskbar = {
        description = "Cloudflare Warp Taskbar";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
        ExecStart = "${pkgs.cloudflare-warp}/bin/warp-taskbar";
        Restart = "always";
        RestartSec = 5;
        User = "root";
        };
    };
}