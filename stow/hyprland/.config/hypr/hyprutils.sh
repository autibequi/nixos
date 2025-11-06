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

toggle_theme() {
    # Alterna entre tema claro e escuro do GNOME e troca o wallpaper
    local current_state
    current_state=$(gsettings get org.gnome.desktop.interface color-scheme)

    if [ "$current_state" = "'prefer-dark'" ]; then
        gsettings set org.gnome.desktop.interface color-scheme prefer-light
        gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3
        notify-send -t 500 "Theme changed to light"
        swww img ~/assets/livewallpapers/gundam.gif --transition-type random
    else
        gsettings set org.gnome.desktop.interface color-scheme prefer-dark
        gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
        notify-send -t 500 "Theme changed to dark"
        swww img ~/assets/livewallpapers/gundam2.gif --transition-type random
    fi
}

waybar_refresh() {
    # reload waybar
    pkill waybar 2>/dev/null
    waybar --config ~/.config/waybar/config.jsonc --style ~/.config/waybar/style.css &
    # reload bongocat
    pkill bongocat 2>/dev/null 
    bongocat --config ~/.config/bongocat/bongocat.conf
}

clipboard_history() {
    cliphist list | rofi -dmenu -i -p "Clipboard History" -markup-rows | cliphist decode | wl-copy
}

hypr_reload() {
    waybar_refresh
    hyprctl reloadr
    notify-send "Hyprland reloaded"
}
