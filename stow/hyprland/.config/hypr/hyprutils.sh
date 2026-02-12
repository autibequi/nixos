#!/bin/sh
workspace_switch() {
    requested_workspace="$1"
    current_workspace=$(hyprctl workspaces -j | jq -r '.[] | select(.focused == true) | .name')

    # Save workspace special or normal in different files
    if [[ "$requested_workspace" =~ ^special:.*$ ]]; then
        echo "$requested_workspace" | sed 's/special://' > ~/.cache/hyprland/hyprutils_special_workspace
    else
        echo "$requested_workspace" > ~/.cache/hyprland/hyprutils_normal_workspace
    fi

    # Finally Switch
    if [[ "$requested_workspace" =~ ^special:.*$ ]]; then
        # Função para alternar para um workspace especial e registrar o último workspace especial acessado
        withoutSpecialWorkspace=$(echo "$requested_workspace" | sed 's/special://')
        echo "$withoutSpecialWorkspace" > ~/.cache/hyprland/hyprutils_special_workspace
        hyprctl dispatch togglespecialworkspace "$withoutSpecialWorkspace"
    else
        # move para o workspace passado como argumento
        hyprctl dispatch workspace "$requested_workspace"
    fi
}

toggle_last_special_workspace(){
    hyprctl dispatch togglespecialworkspace $(cat ~/.cache/hyprland/hyprutils_special_workspace)
}

apply_gtk_theme() {
    local gtk_theme="$1"
    local color_scheme="$2"
    
    # 1. Criar arquivos de configuração GTK3
    mkdir -p "$HOME/.config/gtk-3.0"
    cat > "$HOME/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-theme-name=$gtk_theme
gtk-application-prefer-dark-theme=$([ "$color_scheme" = "prefer-dark" ] && echo "1" || echo "0")
gtk-icon-theme-name=Adwaita
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-enable-animations=true
EOF

    # 2. Criar arquivos de configuração GTK4
    mkdir -p "$HOME/.config/gtk-4.0"
    cat > "$HOME/.config/gtk-4.0/settings.ini" << EOF
[Settings]
gtk-theme-name=$gtk_theme
gtk-application-prefer-dark-theme=$([ "$color_scheme" = "prefer-dark" ] && echo "1" || echo "0")
gtk-icon-theme-name=Adwaita
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-enable-animations=true
EOF

    # 3. Tentar aplicar via gsettings (se schemas estiverem instalados)
    if command -v gsettings &> /dev/null; then
        gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface color-scheme "$color_scheme" 2>/dev/null || true
    fi
    
    # 4. Tentar via dconf direto (mais robusto)
    if command -v dconf &> /dev/null; then
        dconf write /org/gnome/desktop/interface/gtk-theme "'$gtk_theme'" 2>/dev/null || true
        dconf write /org/gnome/desktop/interface/color-scheme "'$color_scheme'" 2>/dev/null || true
    fi
    
    # 5. Exportar variáveis de ambiente para novas aplicações
    export GTK_THEME="$gtk_theme"
    
    # 6. Notificar todas as aplicações GTK rodando (via XSETTINGS)
    # Isso faz apps existentes recarregarem o tema
    killall -SIGHUP xsettingsd 2>/dev/null || true
}

toggle_theme() {
    # Alterna entre tema claro e escuro (Hyprland-native, não depende do GNOME)
    local theme_state_file="$HOME/.cache/hyprland/hyprutils_theme_state"
    local current_theme
    
    # Criar diretório se não existir
    mkdir -p "$HOME/.cache/hyprland"
    
    # Ler tema atual (default: dark)
    if [ -f "$theme_state_file" ]; then
        current_theme=$(cat "$theme_state_file")
    else
        current_theme="dark"
    fi
    
    if [ "$current_theme" = "dark" ]; then
        # Mudar para light
        echo "light" > "$theme_state_file"
        apply_gtk_theme "adw-gtk3" "prefer-light"
        
        notify-send -t 500 "Theme changed to light ☀️"
        swww img ~/assets/livewallpapers/gundam.gif \
            --transition-type fade \
            --transition-fps 60 \
            --transition-duration 0.3
    else
        # Mudar para dark
        echo "dark" > "$theme_state_file"
        apply_gtk_theme "adw-gtk3-dark" "prefer-dark"
        
        notify-send -t 500 "Theme changed to dark 🌙"
        swww img ~/assets/livewallpapers/gundam2.gif \
            --transition-type fade \
            --transition-fps 60 \
            --transition-duration 0.3
    fi
}

waybar_refresh() {
    # reload waybar
    pkill waybar 2>/dev/null
    waybar --config ~/.config/waybar/config.jsonc --style ~/.config/waybar/style.css &
    # reload bongocat (only if AC is plugged in)
    pkill bongocat 2>/dev/null 
    if [ -f /sys/class/power_supply/ADP0/online ] && [ "$(cat /sys/class/power_supply/ADP0/online)" = "1" ]; then
        bongocat --config ~/.config/bongocat/bongocat.conf
    fi
}

clipboard_history() {
    cliphist list | rofi -dmenu -i -p "Clipboard History" -markup-rows | cliphist decode | wl-copy
}

hypr_reload() {
    waybar_refresh
    hyprctl reloadr
    notify-send "Hyprland reloaded"
}
