{
  pkgs,
  unstable,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    mkcert
    nssTools
    lazygit
    # runwithout installing
    comma
    # crap
    sqlite
    cbonsai
    # ── Sistema ────────────────────────────────────────
    bashly
    yq-go # parser YAML CLI — usado pelo plug CLI
    jq # waybar/scripts usam jq diretamente (sem herdar alias jq=jaq do shell)
    killall
    stow
    tailscale
    broot

    # ── Desktop / Wayland ──────────────────────────────
    swww
    rofimoji
    # rofi-wayland
    rofi-unwrapped
    flameshot # PrintScreens

    # ── Aparência ──────────────────────────────────────
    banana-cursor # my boss saw it, it okay
    apple-cursor # to when my boss regret beeing okay
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
    gitkraken
    jujutsu
    gitoxide

    # ── AI / Claude ────────────────────────────────────
    claude-code
    # ── Produtividade ──────────────────────────────────
    proton-pass
    unstable.obsidian
    onlyoffice-desktopeditors
    papers # PDFs

    # ── Midia ──────────────────────────────────────────
    mpv
    foliate # ePub reader
    blanket # Noise
    fragments # GTK4 torrent client (magnet links + notificações)
    # unstable.stremio

    # ── Terminal ───────────────────────────────────────
    tmux
    cool-retro-term
    espeak-ng # TTS for terminal bell
    sox # audio recording (Claude Code /voice)

    # ── Benchmark / Monitoramento ──────────────────────
    geekbench
    fio # I/O benchmark (CrystalDiskMark-style)
    nvtopPackages.full # AMD GPU monitoring

    # ── Games / 3D ─────────────────────────────────────
    godot
    # retroarchFull

    # ── Hardware / Misc ────────────────────────────────
    sidequest # Oculus sideloading
    # cura
    # ventoy-full-qt
    # openrgb_git
    # winboat

    # ── Fun ────────────────────────────────────────────
    unstable.wayland-bongocat
    pokemonsay
    fortune

    home-manager

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
