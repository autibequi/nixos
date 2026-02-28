#!/bin/sh

init() {
    waybar_refresh
    dark_theme
}

# Returns the focused monitor name (e.g. eDP-1, HDMI-A-1, DP-2)
_focused_monitor() {
    hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'
}

# Returns the per-monitor state file path for storing the last special workspace
_special_ws_file() {
    local monitor="${1:-$(_focused_monitor)}"
    echo "$HOME/.cache/hyprland/hyprutils_special_workspace_${monitor}"
}

workspace_switch() {
    requested_workspace="$1"
    local monitor
    monitor=$(_focused_monitor)

    # Save workspace special or normal in per-monitor files
    if [[ "$requested_workspace" =~ ^special:.*$ ]]; then
        local withoutSpecialWorkspace
        withoutSpecialWorkspace=$(echo "$requested_workspace" | sed 's/special://')
        echo "$withoutSpecialWorkspace" > "$(_special_ws_file "$monitor")"
        hyprctl dispatch togglespecialworkspace "$withoutSpecialWorkspace"
    else
        echo "$requested_workspace" > ~/.cache/hyprland/hyprutils_normal_workspace
        # Oculta special workspace ativo antes de trocar
        hide_active_special_workspaces
        # move para o workspace passado como argumento
        hyprctl dispatch workspace "$requested_workspace"
    fi
}

toggle_last_special_workspace(){
    local monitor
    monitor=$(_focused_monitor)
    local last
    last=$(cat "$(_special_ws_file "$monitor")" 2>/dev/null)
    if [ -n "$last" ]; then
        hyprctl dispatch togglespecialworkspace "$last"
    fi
}

hide_active_special_workspaces(){
    # Fecha o special workspace visível no monitor focado
    active=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .specialWorkspace.name')
    if [ -n "$active" ] && [ "$active" != "" ]; then
        name="${active#special:}"
        if [ -n "$name" ]; then
            hyprctl dispatch togglespecialworkspace "$name"
        fi
    fi
}

toggle_or_hide_special_workspace(){
    # Super: apenas oculta o special workspace atual (sem reabrir ao pressionar de novo)
    hide_active_special_workspaces
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
    local alacritty_config="$HOME/.config/alacritty/alacritty.toml"
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

        # Trocar tema do Alacritty para light
        if [ -f "$alacritty_config" ]; then
            sed -i 's|import = \["~/.config/alacritty/dark-theme.toml"\]|import = ["~/.config/alacritty/light-theme.toml"]|g' "$alacritty_config"
        fi

        notify-send -t 500 "Theme changed to light ☀️"
        swww img ~/assets/wallpapers/the-death-of-socrates.jpg \
            --transition-type fade \
            --transition-fps 60 \
            --transition-duration 0.3
    else
        # Mudar para dark
        echo "dark" > "$theme_state_file"
        apply_gtk_theme "adw-gtk3-dark" "prefer-dark"

        # Trocar tema do Alacritty para dark
        if [ -f "$alacritty_config" ]; then
            sed -i 's|import = \["~/.config/alacritty/light-theme.toml"\]|import = ["~/.config/alacritty/dark-theme.toml"]|g' "$alacritty_config"
        fi

        notify-send -t 500 "Theme changed to dark 🌙"
        swww img ~/assets/wallpapers/the-wild-hunt-of-odin.jpg \
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
    # Display clipboard history with preview pane in floating terminal
    # Step 1: Launch alacritty as a floating popup window
    # Step 2: Run fzf with side preview panel inside terminal
    # Step 3: Decode selected entry and copy to clipboard

    alacritty --class="clipboard-history-popup,clipboard-history-popup" \
              --title="Clipboard History" \
              -o window.dimensions.columns=120 \
              -o window.dimensions.lines=30 \
              -e sh -c 'cliphist list | fzf --preview "echo {} | cliphist decode" --preview-window=right:50%:wrap --layout=reverse --prompt="Clipboard History: " --bind "enter:execute(echo {} | cliphist decode | wl-copy)+abort"'
}

print_screen_with_notes() {
    mkdir -p ~/Pictures/printscreens
    hyprshot -m region --raw | satty -f - --early-exit --fullscreen --copy-command wl-copy --init-tool highlight --annotation-size-factor 0.5 --output-filename ~/Pictures/printscreens/$(date +%Y%m%d_%H%M%S).png
}

print_screen_to_clipboard() {
    hyprshot -m region -o ~/Pictures/Screenshots
}

tesseract_region() {
    hyprshot -m region --raw | tesseract stdin stdout -l eng | wl-copy
}

hypr_reload() {
    waybar_refresh
    hyprctl reloadr
    notify-send "Hyprland reloaded"
}
