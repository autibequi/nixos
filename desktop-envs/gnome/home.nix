{ pkgs, lib, ... }:
{
  home-manager.users."pedrinho" = { pkgs, lib, ... }:
  {
    gtk = {
      enable = true;
      theme.name = "Adwaita";
      iconTheme.name = "Papirus";
    };
    
    dconf = {
      enable = true;
      settings = {
        # Configurações dconf originais de de.nix
        "org/gnome/desktop/peripherals/mouse" = {
          natural-scroll = true;
        };
        "org/gnome/mutter" = {
            experimental-features = [ "scale-monitor-framebuffer" "variable-refresh-rate" ];
        };
        "org/gnome/settings-daemon/plugins/sound" = {
          volume-step = 0.1;
        };
        "org/gnome/desktop/applications/terminal" = {
          exec = "${pkgs.ghostty}/bin/ghostty";
        };
        "org/gnome/desktop/interface" = {
            cursor-size = 40;
            cursor-theme = "banana";
        };
        "org/gnome/gnome-panel/layout" = { # Pode não ter efeito no Gnome Shell moderno
          bottom-panel = true;
        };
        "org/gnome/desktop/wm/preferences" = {
          focus-mode = "sloppy";
        };

        # Atalhos de teclado solicitados
        "org/gnome/desktop/wm/keybindings" = {
          "switch-to-workspace-left" = ["<Super>a"];
          "switch-to-workspace-right" = ["<Super>d"];
          "switch-to-workspace-up" = ["disabled"];
          "switch-to-workspace-down" = ["disabled"];
          "move-to-workspace-left" = ["<Alt>a"];
          "move-to-workspace-right" = ["<Alt>d"];
          "move-to-workspace-up" = ["disabled"];
          "move-to-workspace-down" = ["disabled"];
        };
        "org/gnome/shell/keybindings" = {
          "toggle-overview" = ["<Super>w"];
        };
      };
    };
  };
} 