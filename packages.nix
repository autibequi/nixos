{ config, pkgs, lib, ... } :

{
    environment.systemPackages = with pkgs; [
        # essentials
        vim
        wget
        unixtools.whereis
        mission-center
        pciutils

        # Stuff
        steam
        obsidian

        # Utils
        gnumake
        coreutils-full
        atuin

        # TODO:Test
        nushell
        pueue
        starship
        zed-editor

        #cliiiiiii
        btop   # better top
    ];

    programs.openvpn3.enable = true;

    programs.neovim.enable = true;
    programs.neovim.defaultEditor = true;

}