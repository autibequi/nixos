{
  ...
}:
{
  # Importa Setup do Usuario
  imports = [
    # Hardware Configurations
    ./hardware.nix

    # Core Modules
    ./modules/core/nix.nix
    ./modules/core/core.nix
    ./modules/core/services.nix
    ./modules/core/programs.nix
    ./modules/core/packages.nix
    ./modules/core/fonts.nix
    ./modules/core/shell.nix
    ./modules/core/kernel.nix
    ./modules/core/hibernate.nix

    # Greeter
    ./modules/greetd.nix

    # Stable Modules
    ./modules/logiops.nix
    ./modules/bluetooth.nix
    ./modules/plymouth.nix
    ./modules/ai.nix
    ./modules/whisper-ptt.nix
    ./modules/steam.nix
    ./modules/containers.nix

    # Hardware Specific
    ./modules/asus.nix
    ./modules/nvidia.nix

    # Desktop Environments
    ./modules/hyprland.nix

    # Monitoring
    ./modules/netdata.nix

    # Agentes (CLAUDINHO timers + agent-container)
    ./modules/agents

    # Obsidian Sync (headless)
    ./modules/obsidian-sync.nix

    # OpenClaw Gateway
    ./modules/openclaw.nix

    # LM Studio Server
    ./modules/lmstudio.nix

    # Other Modules
    ./modules/work.nix
    ./modules/virt.nix

  ];
}
