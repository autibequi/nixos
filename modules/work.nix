{ config, pkgs, lib, ... } :
{

    # Environment Variables
    environment.sessionVariables = {
        CGO_ENABLED=1; # kafka
        GOPRIVATE="github.com/estrategiahq/*";
    };

    # Systemd Packages
    environment.systemPackages = with pkgs; [
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

        # work browser
        vivaldi
        chromium

        # TESTING:
        github-copilot-cli
        devbox
        pkgs.code-cursor
        # TODO: try to make this work to use nixGLNvidiaBumblebee and improve performance
        # (pkgs.nixgl.auto.nixGLDefault pkgs.code-cursor)
        zed-editor
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

    home-manager.users."pedrinho" = { pkgs, ... }: {
        programs.git = {
            enable = true;
            userName  = "Pedro Correa";
            userEmail = "pedro.correa@estrategia.com";
        };
    };
}