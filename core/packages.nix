{ config, pkgs, lib, ... } :

{
    environment.systemPackages = with pkgs; [
        # apps
        mpv
        onlyoffice-bin
        brave
        mission-center
        sidequest # for oculus sideloading
        stremio
        obsidian
        blanket
        # cura
        # ventoy-full-qt


        # Aesthetics
        # Cursors
        banana-cursor
        apple-cursor
        bibata-cursors
        oreo-cursors-plus

        # Icons
        papirus-icon-theme


        # Testing!
        # webcamoid
        # Testing!
        # obs-studio

        # AI
        windsurf
        # openai-whisper-cpp
        # whisper-cpp
        # whisper-cpp-vulkan # Voice-To-Text - for blurt gnome extension
    ];
}