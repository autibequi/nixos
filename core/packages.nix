{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # apps
    onlyoffice-bin # office space apps
    sidequest # for oculus sideloading
    stremio # yaaaaaaaarh
    blanket # Noise
    papers # PDFS
    flameshot # PrintScreens
    obsidian # Md Notes
    mpv # media/shoes/chocolate player

    # Aesthetics
    banana-cursor # my boss saw it, it okay
    apple-cursor # to when my boss regret beeing okay
    papirus-icon-theme # Icons

    # ZED EDITOR
    # # latest git build
    # zed-editor_git
    zed-editor-fhs_git # nixer version

    # Ganes
    # retroarchFull

    # Terminal
    ghostty
    # warp-terminal
    # allacritty

    # should be working
    # cura
    # ventoy-full-qt
  ];
}
