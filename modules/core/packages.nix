{
  pkgs,
  unstable,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    fuse-overlayfs

    # ── Sistema ────────────────────────────────────────
    bashly
    jq # waybar/scripts usam jq diretamente (sem herdar alias jq=jaq do shell)
    killall
    stow
    tailscale

    # ── Desktop / Wayland ──────────────────────────────
    swww
    rofimoji
    # rofi-wayland
    rofi-unwrapped
    flameshot # PrintScreens

    # ── Aparência ──────────────────────────────────────
    banana-cursor # my boss saw it, it okay
    apple-cursor  # to when my boss regret beeing okay
    papirus-icon-theme

    # ── Browsers ───────────────────────────────────────
    chromium
    google-chrome
    vivaldi
    vivaldi-ffmpeg-codecs
    # servo # rust browser
    # inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default

    # ── Editores / Dev ─────────────────────────────────
    unstable.zed-editor
    # inputs.zed.packages.${pkgs.system}.default
    gitkraken
    jujutsu
    gitoxide

    # ── AI / Claude ────────────────────────────────────
    claude-code
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

    # ── Produtividade ──────────────────────────────────
    proton-pass
    unstable.obsidian
    onlyoffice-desktopeditors
    papers  # PDFs

    # ── Midia ──────────────────────────────────────────
    mpv
    foliate  # ePub reader
    blanket  # Noise
    fragments  # GTK4 torrent client (magnet links + notificações)
    # unstable.stremio

    # ── Terminal ───────────────────────────────────────
    tmux
    cool-retro-term
    espeak-ng  # TTS for terminal bell
    sox        # audio recording (Claude Code /voice)

    # ── Benchmark / Monitoramento ──────────────────────
    geekbench
    fio                  # I/O benchmark (CrystalDiskMark-style)
    nvtopPackages.full   # AMD GPU monitoring

    # ── Games / 3D ─────────────────────────────────────
    godot
    # retroarchFull

    # ── Hardware / Misc ────────────────────────────────
    sidequest  # Oculus sideloading
    # cura
    # ventoy-full-qt
    # openrgb_git
    # winboat

    # ── Fun ────────────────────────────────────────────
    unstable.wayland-bongocat
    pokemonsay
    fortune

    # ── Testando ───────────────────────────────────────
    # evil-helix_git
    # unstable.howdy
    # inputs.antigravity-nix.packages.${pkgs.system}.default
    # inputs.voxtype.packages.${pkgs.system}.vulkan
  ];
  # permittedInsecurePackages = [
  #   "ventoy-qt5-1.1.05"
  # ];
}
