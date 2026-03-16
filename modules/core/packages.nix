{
  pkgs,
  unstable,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    bashly
    
    proton-pass
    stow
    rofimoji
    rofi-top
    # rofi-wayland
    rofi-unwrapped
    rofi-emoji

    killall
    # apps
    onlyoffice-desktopeditors # office space apps
    sidequest # for oculus sideloading
    blanket # Noise
    papers # PDFS
    flameshot # PrintScreens
    unstable.obsidian # Md Notes
    claude-code # AI coding assistant
    (python3Packages.buildPythonApplication rec {
      pname = "claude-statusbar";
      version = "1.3.1";
      src = fetchFromGitHub {
        owner = "leeguooooo";
        repo = "claude-code-usage-bar";
        rev = "main";
        sha256 = "0wp2mmrxpbahp66l8imf0gv674graq8i0z6is6rkwsd0rfyxwab0";
      };
      pyproject = true;
      nativeBuildInputs = [ python3Packages.setuptools ];
      propagatedBuildInputs = [ ];
      doCheck = false;
    })
    mpv # media/shoes/chocolate player
    foliate # ePub reader
    fragments # torrent client
    discord # chattery
    # unstable.stremio # streaming

    # Aesthetics
    banana-cursor # my boss saw it, it okay
    apple-cursor # to when my boss regret beeing okay
    papirus-icon-theme # Icons

    # ZED EDITOR (nightly via flake)
    # inputs.zed.packages.${pkgs.system}.default
    unstable.zed-editor

    # Work Browser
    chromium
    google-chrome
    # servo # rust browser
    # inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    vivaldi
    vivaldi-ffmpeg-codecs

    # art
    # krita

    # benchmark
    geekbench
    fio # I/O benchmark (CrystalDiskMark-style sequential)
    nvtopPackages.full # AMD GPU monitoring

    # Games
    # retroarchFull
    godot

    # Terminal
    cool-retro-term
    espeak-ng # TTS for terminal bell
    sox # audio recording (Claude Code /voice)

    # should be working (but its not)
    # cura
    # ventoy-full-qt

    # ---------------
    # Checking out
    # openrgb_git
    # evil-helix_git
    tailscale
    # ISO
    # ventoy-full-qt

    # Windows Nomopoly Mitigations:
    # winboat

    # voxtype-vulkan-unwrapped
    # inputs.voxtype.packages.${pkgs.system}.vulkan

    # Fun
    unstable.wayland-bongocat
    pokemonsay
    fortune

    # unstable.howdy

    # Google Antigravity (agentic IDE)
    # inputs.antigravity-nix.packages.${pkgs.system}.default
  ];
  # permittedInsecurePackages = [
  #   "ventoy-qt5-1.1.05"
  # ];
}
