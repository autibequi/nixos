{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    killall
    # apps
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
    zed-editor
    # zed-editor_git # can sudo
    # zed-editor-fhs_git # cant sudo

    # BROWSER
    chromium # work browser

    # Games
    # retroarchFull

    # Terminal
    ghostty
    # warp-terminal
    # allacritty

    # should be working
    # cura
    # ventoy-full-qt

    # ---------------
    # Checking out
    # openrgb_git
    # evil-helix_git

    # ISO
    ventoy-full-qt
  ];
  permittedInsecurePackages = [
    "ventoy-qt5-1.1.05"
  ];
}
