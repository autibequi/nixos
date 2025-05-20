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
        # Interface e Aparência
        "org/gnome/desktop/interface" = {
          cursor-size = 40;
          cursor-theme = "banana";
          enable-animations = false;
        };
        
        # Mouse e Periféricos
        "org/gnome/desktop/peripherals/mouse" = {
          natural-scroll = true;
        };
        
        "org/gnome/desktop/wm/preferences" = {
          focus-mode = "sloppy"; # sloppy (hover focus), smart (click focus), click, none
        };
        
        # Keybindings
        "org/gnome/desktop/wm/keybindings" = {
          # Workspace Management
          "switch-to-workspace-left" = ["<Super>a"];
          "switch-to-workspace-right" = ["<Super>d"];
          "move-to-workspace-left" = ["<Super>q"];
          "move-to-workspace-right" = ["<Super>e"];

          # Window Management
          "close" = ["<Super>Escape"];
          "maximize" = ["<Super>w"];
          "minimize" = ["<Super>s"];
        };
        
        "org/gnome/shell/keybindings" = {
          "toggle-overview" = ["<Super>z"];
          "toggle-message-tray" = ["<Super>x"];
          "toggle-application-menu" = ["<Super>c"];
        };
        
        # Extensões
        # Vitals
        "org/gnome/shell/extensions/vitals" = {
          hot-sensors = ["_processor_usage_" "_memory_usage_" "_battery_rate_" "_battery_time_left_" "_temperature_acpi_thermal zone_"];
        };
      };
    };
  };
}