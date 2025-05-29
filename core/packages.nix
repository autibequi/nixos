{ pkgs, ... }:

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
    flameshot

    # Coding
    # Nix formating
    nil
    nixd
    nixfmt-rfc-style

    # Editor
    zed-editor
    # zed-editor-fhs # correcter but no sudo on terminal

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

    # Rust
    cargo
    rustc
    rustup
    rust-analyzer
    rustfmt
    clippy
    rust-analyzer

    # AI
    windsurf
    aider-chat-full
    # openai-whisper-cpp
    # whisper-cpp
    # whisper-cpp-vulkan # Voice-To-Text - for blurt gnome extension
  ];
}
