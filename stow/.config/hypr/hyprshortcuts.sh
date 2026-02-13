#!/usr/bin/env bash

# This script parses the output of `hyprctl binds`, displays it in Rofi,
# and executes the selected command.
# It handles the verbose, multi-line format from recent hyprctl versions.

# Function to decode the modifier mask from a number to a human-readable string.
decode_modmask() {
    local mask=$1
    local mods=""

    # Bitwise checks for each modifier mask value.
    # These values are standard for Hyprland.
    # 64: Super (Windows key)
    # 32: Mod3 (e.g., Caps Lock as Hyper)
    # 8:  Alt
    # 4:  Ctrl
    # 1:  Shift
    if [ $((mask & 64)) -ne 0 ]; then mods="${mods}Super+"; fi
    if [ $((mask & 32)) -ne 0 ]; then mods="${mods}Mod3+"; fi
    if [ $((mask & 8)) -ne 0 ]; then mods="${mods}Alt+"; fi
    if [ $((mask & 4)) -ne 0 ]; then mods="${mods}Ctrl+"; fi
    if [ $((mask & 1)) -ne 0 ]; then mods="${mods}Shift+"; fi

    # Remove the trailing "+" if any modifiers were found.
    printf "%s" "${mods%+}"
}

# Associative array to map the display string to the command to execute
declare -A binds_map

# An array to hold the lines to be displayed in Rofi, for sorting purposes.
declare -a display_lines=()

# The awk script to parse hyprctl output remains the same.
# We redirect its output to the while loop.
while IFS=';' read -r modmask key dispatcher arg; do
    # Skip empty keys, which can happen with mouse binds without a clear key name.
    if [ -z "$key" ]; then
        continue
    fi

    # Decode the modifier mask into a string like "Super+Shift"
    mods=$(decode_modmask "$modmask")

    # Format the final key combination string
    if [ -n "$mods" ]; then
        pretty_key="$mods+$key"
    else
        pretty_key="$key"
    fi

    # Make the action part pretty and more descriptive for Rofi.
    case "$dispatcher" in
        "exec")
            if echo "$arg" | grep -q "workspace_switch"; then
                ws_name=$(echo "$arg" | sed -n 's/.*workspace_switch \(.*\)/\1/p')
                pretty_action="Go to W: $ws_name"
            else
                pretty_action="Run: $arg"
            fi
            ;;
        "killactive")        pretty_action="Close Window" ;;
        "exit")              pretty_action="Exit Hyprland" ;;
        "togglefloating")    pretty_action="Toggle Float" ;;
        "fullscreen")        pretty_action="Toggle Fullscreen" ;;
        "movetoworkspace" | "movetoworkspacesilent") pretty_action="Move to W: $arg" ;;
        "workspace")         pretty_action="Go to W: $arg" ;;
        "submap")            pretty_action="[SUBMAP] $arg" ;;
        "movefocus")         pretty_action="Focus: $arg" ;;
        "movewindow")        pretty_action="Move Window: $arg" ;;
        "resizeactive")      pretty_action="Resize: $arg" ;;
        "mouse")             pretty_action="Mouse Action: $arg" ;;
        *)                   pretty_action="$dispatcher $arg" ;;
    esac

    # Construct the command to be executed when a line is selected.
    local cmd
    if [[ "$dispatcher" == "exec" ]]; then
        cmd="$arg"
    else
        cmd="hyprctl dispatch $dispatcher $arg"
    fi

    # The string to be displayed in Rofi for this binding.
    display_str=$(printf '<span>%-25s</span> %s' "$pretty_key" "$pretty_action")

    # We use the pretty_action as the sort key.
    # We store "sort_key<TAB>display_string<TAB>command" for later processing.
    display_lines+=("$(printf '%s\t%s\t%s' "$pretty_action" "$display_str" "$cmd")")

done < <(hyprctl binds | awk '
BEGIN { OFS=";" }
/^bind(e|m|l)?/ {
    if (key != "") print modmask, key, dispatcher, arg
    modmask="0"; key=""; dispatcher=""; arg=""
}
/^\s+modmask:/ { modmask = $2 }
/^\s+key:/ { key = $2 }
/^\s+dispatcher:/ { dispatcher = $2 }
/^\s+arg:/ {
    match($0, /^\s+arg: (.*)/, arr)
    arg = arr[1]
}
END {
    if (key != "") print modmask, key, dispatcher, arg
}
')

# Prepare the input for Rofi and populate the map.
# We sort the lines by the sort_key (first column).
rofi_input=""
while IFS=$'\t' read -r sort_key display_str cmd; do
    rofi_input+="${display_str}\n"
    binds_map["$display_str"]="$cmd"
done < <(printf "%s\n" "${display_lines[@]}" | sort)

# Launch Rofi. It will display the list of shortcuts.
selection=$(echo -en "$rofi_input" | rofi -dmenu -i -p "Shortcuts" -width 150 -markup-rows)

# If the user selected an item, execute the corresponding command.
if [ -n "$selection" ]; then
    command="${binds_map["$selection"]}"
    if [ -n "$command" ]; then
        # Use eval to correctly handle complex shell commands (like those with '&&' or ';').
        # Run in the background so Rofi closes instantly.
        eval "$command" &
    fi
fi
