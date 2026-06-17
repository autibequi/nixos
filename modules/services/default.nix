{ ... }:
{
  # Services: daemons opt-in e serviços de aplicação.
  imports = [
    ./ai.nix # ferramentas de IA local (lmstudio, cursor, upscayl)
    ./lmstudio.nix # opção services.lmstudio (server headless; default off)
    ./obsidian-sync.nix # sync headless do vault + indicador no tray
    ./steam.nix # Steam + gamescope + mangohud
    ./virt.nix # QEMU/KVM + virt-manager
    # ./ramsync.nix # profile-em-RAM (psd browsers + caches Zed/Obsidian em tmpfs)
  ];
}
