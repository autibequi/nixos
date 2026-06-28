{ ... }:
{
  # Services: daemons opt-in e serviços de aplicação.
  imports = [
    ./ai.nix # ferramentas de IA local (lmstudio, cursor, upscayl)
    ./lmstudio.nix # opção services.lmstudio (server headless; default off)
    ./obsidian-sync.nix # sync headless do vault + indicador no tray
    ./host-perf.nix # sampler de performance em background (logger p/ ! host-perf)
    ./steam.nix # Steam + gamescope + mangohud
    ./virt.nix # QEMU/KVM + virt-manager
    ./hyprland-logs.nix # exporta logs de apps custom → ~/nixos/logs/ (visível em /workspace/host/logs/)
    ./downloads-cleanup.nix # screenshots +7d, Downloads → Pictures / Documents/missplaced
    ./ydotool.nix # daemon uinput para injeção de teclas sem modifier leakage
    # ./ramsync.nix # profile-em-RAM (psd browsers + caches Zed/Obsidian em tmpfs)
  ];
}
