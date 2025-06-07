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
    papers # for reading academic papers
    # cura
    # ventoy-full-qt
    flameshot
    retroarchFull

    #  LSP for markdonw?
    markdown-oxide

    # Coding
    # Nix formating
    nil
    nixd
    nixfmt-rfc-style

    # Editor
    # zed-editor  # wrongest
    zed-editor_git # latest git build
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

    # AI
    windsurf
    opencode
    # openai-whisper-cpp
    # whisper-cpp
    # whisper-cpp-vulkan # Voice-To-Text - for blurt gnome extension
  ];
}
