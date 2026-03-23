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
    grim -g "$(slurp)" - | satty -f - --early-exit --fullscreen --copy-command wl-copy --init-tool highlight --annotation-size-factor 0.5 --output-filename ~/Pictures/printscreens/$(date +%Y%m%d_%H%M%S).png
}

print_screen_to_clipboard() {
    mkdir -p ~/Pictures/Screenshots
    local outfile=~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png
    if grim -g "$(slurp)" - | tee "$outfile" | wl-copy; then
        notify-send -a "Screenshot" "Capturado" "Copiado para clipboard" -u low
    else
        notify-send -a "Screenshot" "Falhou" "grim ou wl-copy retornou erro" -u critical
    fi
}

print_screen_full_then_crop() {
    mkdir -p ~/Pictures/printscreens
    local tmpfile monitor
    tmpfile=$(mktemp /tmp/screenshot_XXXXXX.png)
    monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')
    grim -o "$monitor" "$tmpfile" && satty -f "$tmpfile" --early-exit --fullscreen --copy-command wl-copy --init-tool crop --annotation-size-factor 0.5 --output-filename ~/Pictures/printscreens/$(date +%Y%m%d_%H%M%S).png
    rm -f "$tmpfile"
}

tesseract_region() {
    local text
    text=$(grim -g "$(slurp)" - | tesseract stdin stdout -l eng 2>/dev/null)
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

# Focus left/right without wrap: stops at leftmost/rightmost column in the workspace
# Usage: focus_no_wrap l | focus_no_wrap r
focus_no_wrap() {
    local direction="$1"
    local win_info win_x ws_id count
    win_info=$(hyprctl -j activewindow | jaq -r '"\(.at[0]) \(.workspace.id)"')
    win_x=$(echo "$win_info" | cut -d' ' -f1)
    ws_id=$(echo "$win_info" | cut -d' ' -f2)
    if [ "$direction" = "r" ]; then
        count=$(hyprctl -j clients | jaq "[.[] | select(.workspace.id == $ws_id) | select(.at[0] > $win_x)] | length")
    else
        count=$(hyprctl -j clients | jaq "[.[] | select(.workspace.id == $ws_id) | select(.at[0] < $win_x)] | length")
    fi
    [ "$count" -eq 0 ] && return
    hyprctl dispatch layoutmsg "focus $direction"
}

# Colresize without wrap: stops at min (0.2) and max (1.0) instead of cycling
# Usage: colresize_no_wrap + | colresize_no_wrap -
# NOTE: activewindow.size is in logical px; monitors.width is physical px — must divide by scale
colresize_no_wrap() {
    local direction="$1"
    local win_w mon_info mon_w
    win_w=$(hyprctl -j activewindow | jaq -r '.size[0]')
    mon_info=$(hyprctl -j monitors | jaq -r '.[] | select(.focused == true) | "\(.width) \(.scale)"')
    mon_w=$(awk "BEGIN { split(\"$mon_info\", a); printf \"%d\", a[1] / a[2] }")
    if [ "$direction" = "+" ]; then
        awk "BEGIN { exit !($win_w / $mon_w >= 0.85) }" && return
    else
        awk "BEGIN { exit !($win_w / $mon_w <= 0.22) }" && return
    fi
    hyprctl dispatch layoutmsg "colresize ${direction}conf"
}

# Dispatcher: allows calling any function by name
# Usage: ./hyprutils.sh workspace_switch 1
if [ $# -gt 0 ]; then
    "$@"
fi
