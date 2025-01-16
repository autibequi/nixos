{ config, pkgs, lib, ... } :
{

      # Environment Variables
    environment.sessionVariables = {
        CGO_ENABLED=1; # kafka
    };

    environment.systemPackages = with pkgs; [
        # Tools
        dbeaver-bin
        insomnia
        podman

        # Work/Estrategia
        cloudflare-warp
        chromium
        python314
        poetry
        vscode
        gradle
        go
        terraform

        # Node
        nodejs_23

        # Flutter
        flutter
        android-studio
        android-tools
        dart

        # ai shit
        github-copilot-cli

        # hacking stuff
        dig
        awscli2
        openvpn

        k9s # kubernets cli
        kubectl

        #golang pprof
        graphviz

        # kafka go
        libgcc
    ];
}