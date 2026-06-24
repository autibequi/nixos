{
  pkgs,
  unstable,
  inputs,
  ...
}:

{
  # Pacotes de sistema ATIVOS (sempre instalados). Os opt-in (servo, godot,
  # ventoy, digikam, etc) vivem comentados em system/packages-extra.nix.
  environment.systemPackages = with pkgs; [
    firefox
    gthumb
    mkcert
    nssTools
    lazygit
    comma # roda pacote sem instalar (precisa do db do nix-index pra achar tudo)
    sqlite

    # security
    yubikey-manager

    cbonsai
    # ── Sistema ────────────────────────────────────────
    bashly
    yq-go # parser YAML CLI — usado pelo plug CLI
    jq # waybar/scripts usam jq diretamente (sem herdar alias jq=jaq do shell)
    killall
    stow
    tailscale
    broot

    easyeffects

    # ── Desktop / Wayland ──────────────────────────────
    awww
    rofimoji
    rofi-unwrapped
    flameshot # PrintScreens

    # ── Aparência ──────────────────────────────────────
    banana-cursor # my boss saw it, it okay
    apple-cursor # to when my boss regret beeing okay
    papirus-icon-theme

    # ── Browsers ───────────────────────────────────────
    chromium
    google-chrome

    # ── Editores / Dev ─────────────────────────────────
    # zed-editor: ver modules/apps/zed.nix (binário oficial pré-compilado)
    gitkraken
    jujutsu
    gitoxide

    # ── Produtividade ──────────────────────────────────
    proton-pass
    unstable.obsidian
    onlyoffice-desktopeditors
    papers # PDFs

    # ── Midia ──────────────────────────────────────────
    (pkgs.mpv.override {
      scripts = with pkgs.mpvScripts; [
        uosc # UI moderna com seekbar, playlist e file browser
        thumbfast # thumbnails ao passar o mouse na seekbar
      ];
    })
    foliate # ePub reader
    blanket # Noise
    fragments # GTK4 torrent client (magnet links + notificações)

    # ── Terminal ───────────────────────────────────────
    tmux
    espeak-ng # TTS for terminal bell
    sox # audio recording (Claude Code /voice)
    socat # bridge TCP — usado pelo yaa chrome pra expor CDP do host ao container

    # ── Monitoramento ──────────────────────────────────
    nvtopPackages.full # AMD GPU monitoring

    # ── X11 / Misc ─────────────────────────────────────
    xhost
    # gnome-disk-utility: instalado em desktop/hyprland/packages.nix

    # ── Fun ────────────────────────────────────────────
    unstable.wayland-bongocat
    pokemonsay
    fortune

    # ── AI Agents ──────────────────────────────────────
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.coderabbit-cli
  ];
}
