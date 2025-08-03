#!/bin/sh

escape_workspace() {
    # Função para sair de um workspace especial e ir para o workspace desejado
    local workspace_number="$1"
    local active_special_workspace
    active_special_workspace=$(hyprctl monitors -j | jq -r '.[] | .specialWorkspace.name')
    echo "ACTIVE_SPECIAL_WORKSPACE: $active_special_workspace"
    echo "workspace_number: $workspace_number"

    if [[ "$active_special_workspace" =~ ^special:.*$ ]]; then
        # remove o prefixo special:
        local clean_name
        clean_name=$(echo "$active_special_workspace" | sed 's/^special://')
        echo "clean_name: $clean_name"
        hyprctl dispatch togglespecialworkspace "$clean_name"
    fi

    # move para o workspace passado como argumento
    hyprctl dispatch workspace "$workspace_number"
}

switch_special_workspace() {
    # Função para alternar para um workspace especial e registrar o último workspace especial acessado
    local workspace_number="$1"
    echo "$workspace_number" > /tmp/last_special_workspace
    hyprctl dispatch togglespecialworkspace "$workspace_number"
}

toggle_theme() {
    # Alterna entre tema claro e escuro do GNOME e troca o wallpaper
    local current_state
    current_state=$(gsettings get org.gnome.desktop.interface color-scheme)

    if [ "$current_state" = "'prefer-dark'" ]; then
        gsettings set org.gnome.desktop.interface color-scheme prefer-light
        gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3
        swww img ~/.wallpapers/light.jpg --transition-fps 120 --transition-step 200
        notify-send -t 500 "Theme changed to light"
    else
        gsettings set org.gnome.desktop.interface color-scheme prefer-dark
        gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
        swww img ~/.wallpapers/dark.jpg --transition-fps 120 --transition-step 200
        notify-send -t 500 "Theme changed to dark"
    fi
}

waybar_refresh() {
    pkill waybar && waybar &
    notify-send "Waybar refreshed"
}
