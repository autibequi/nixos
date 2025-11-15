{ pkgs, inputs, pkgs-unstable, ... }:

{
  environment.systemPackages = with pkgs; [
    proton-pass
    stow
    rofimoji
    rofi-top
    # rofi-wayland
    rofi-wayland-unwrapped
    rofi-emoji-wayland
    
    killall
    # apps
    fuse # Required for AppImage support (libfuse.so.2)
    appimage-run # Wrapper to run AppImages on NixOS
    onlyoffice-bin # office space apps
    sidequest # for oculus sideloading
    stremio # yaaaaaaaarh
    blanket # Noise
    papers # PDFS
    flameshot # PrintScreens
    obsidian # Md Notes
    mpv # media/shoes/chocolate player
    foliate # ePub reader
    fragments # torrent client
    discord # chattery

    # Aesthetics
    banana-cursor # my boss saw it, it okay
    apple-cursor # to when my boss regret beeing okay
    papirus-icon-theme # Icons

    # ZED EDITOR
    pkgs-unstable.zed-editor-fhs

    # Work Browser
    chromium
    google-chrome
    servo # rust browser

    # art
    krita

    # Cursor
    banana-cursor
    apple-cursor

    # Icons
    papirus-icon-theme

    # benchmark
    geekbench

    # Games
    # retroarchFull

    # Terminal
    ghostty
    # warp-terminal
    # allacritty

    # should be working (but its not)
    # cura
    # ventoy-full-qt

    # ---------------
    # Checking out
    # openrgb_git
    # evil-helix_git

    # ISO
    # ventoy-full-qt

    # Windows Nomopoly Mitigations:
    # inputs.winboat.packages.${pkgs.system}.winboat
    # freerdp3 # Required by WinBoat for RDP connections

    # Fun
    pkgs-unstable.wayland-bongocat
  ];
  # permittedInsecurePackages = [
  #   "ventoy-qt5-1.1.05"
  # ];
}
