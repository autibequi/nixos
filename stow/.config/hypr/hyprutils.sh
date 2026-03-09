#!/bin/sh

# Theme helpers (dark_theme, light_theme, toggle_theme)
# shellcheck source=theme.sh
. "${HYPRLAND_CONFIG:-$HOME/.config/hypr}/theme.sh"

# Returns the focused monitor name (e.g. eDP-1, HDMI-A-1, DP-2)
_focused_monitor() {
    hyprctl monitors -j | jaq -r '.[] | select(.focused == true) | .name'
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
    case "$requested_workspace" in
        special:*)
            local withoutSpecialWorkspace
            withoutSpecialWorkspace=$(echo "$requested_workspace" | sed 's/special://')
            echo "$withoutSpecialWorkspace" > "$(_special_ws_file "$monitor")"
            # Check if the special workspace is currently visible (meaning toggle will hide it)
            local active_special
            active_special=$(hyprctl monitors -j | jaq -r '.[] | select(.focused == true) | .specialWorkspace.name')
            hyprctl dispatch togglespecialworkspace "$withoutSpecialWorkspace"
            # If it was visible, we just hid it — kill rofi so it doesn't linger
            if [ "$active_special" = "special:$withoutSpecialWorkspace" ]; then
                pkill -x rofi 2>/dev/null
            fi
            ;;
        *)
            echo "$requested_workspace" > ~/.cache/hyprland/hyprutils_normal_workspace
            # Oculta special workspace ativo antes de trocar
            hide_active_special_workspaces
            # move para o workspace passado como argumento
            hyprctl dispatch workspace "$requested_workspace"
            ;;
    esac
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
    active=$(hyprctl monitors -j | jaq -r '.[] | select(.focused == true) | .specialWorkspace.name')
    if [ -n "$active" ] && [ "$active" != "" ]; then
        name="${active#special:}"
        if [ -n "$name" ]; then
            hyprctl dispatch togglespecialworkspace "$name"
            pkill -x rofi 2>/dev/null
        fi
    fi
}

toggle_or_hide_special_workspace(){
    # Super: apenas oculta o special workspace atual (sem reabrir ao pressionar de novo)
    hide_active_special_workspaces
}

waybar_refresh() {
    # reload waybar
    pkill waybar 2>/dev/null
    uwsm app -- waybar --config ~/.config/waybar/config.jsonc --style ~/.config/waybar/style.css &
    # reload bongocat (only if AC is plugged in)
    pkill bongocat 2>/dev/null
    if [ -f /sys/class/power_supply/ADP0/online ] && [ "$(cat /sys/class/power_supply/ADP0/online)" = "1" ]; then
        uwsm app -- bongocat --config ~/.config/bongocat/bongocat.conf
    fi
}

clipboard_history() {
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
    local text
    text=$(hyprshot -m region --raw | tesseract stdin stdout -l eng 2>/dev/null)
    if [ -n "$text" ]; then
        printf "%s" "$text" | wl-copy
        notify-send -a "OCR" "Texto extraído" "$text" -u low
    else
        notify-send -a "OCR" "OCR falhou" "Nenhum texto detectado na região" -u low
    fi
}

hypr_reload() {
    swaync-client -rs -R
    waybar_refresh
    hyprctl reload
    notify-send "Hyprland reloaded" -u low
}

# Dispatcher: allows calling any function by name
# Usage: ./hyprutils.sh workspace_switch 1
if [ $# -gt 0 ]; then
    "$@"
fi
