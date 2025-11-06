#!/bin/sh

# This script parses the output of `hyprctl binds` and displays it in Rofi.
# It handles the verbose, multi-line format from recent hyprctl versions.

# Function to decode the modifier mask from a number to a human-readable string.
decode_modmask() {
    local mask=$1
    local mods=""

    # Bitwise checks for each modifier mask value.
    # These values are standard for Hyprland.
    # 64: Super (Windows key)
    # 8:  Alt
    # 4:  Ctrl
    # 1:  Shift
    if [ $((mask & 64)) -ne 0 ]; then mods="${mods}Super+"; fi
    if [ $((mask & 8)) -ne 0 ]; then mods="${mods}Alt+"; fi
    if [ $((mask & 4)) -ne 0 ]; then mods="${mods}Ctrl+"; fi
    if [ $((mask & 1)) -ne 0 ]; then mods="${mods}Shift+"; fi

    # Remove the trailing "+" if any modifiers were found.
    printf "%s" "${mods%+}"
}

# Use awk to parse the block-style output of `hyprctl binds` into a
# machine-friendly, semicolon-separated format. This makes it easy to read
# in the shell loop below.
# Output format: MODMASK;KEY;DISPATCHER;ARG
hyprctl binds | awk '
BEGIN { OFS=";" }
# A line starting with "bind" marks a new record.
# When we see one, we print the previously accumulated record.
/^bind(e|m|l)?/ {
    if (key != "") print modmask, key, dispatcher, arg
    # Reset variables for the new record
    modmask="0"; key=""; dispatcher=""; arg=""
}
# Extract values for each field
/^\s+modmask:/ { modmask = $2 }
/^\s+key:/ { key = $2 }
/^\s+dispatcher:/ { dispatcher = $2 }
/^\s+arg:/ {
    # Capture everything after "arg: " to handle args with spaces
    match($0, /^\s+arg: (.*)/, arr)
    arg = arr[1]
}
# After processing all lines, print the last accumulated record.
END {
    if (key != "") print modmask, key, dispatcher, arg
}
' | while IFS=';' read -r modmask key dispatcher arg; do

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
    # This can be easily customized to change how actions are displayed.
    case "$dispatcher" in
        "exec")              pretty_action="Run: $arg" ;;
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
        *)                   pretty_action="$dispatcher $arg" ;; # Catch-all
    esac

    # Format for Rofi: "Action « Key"
    echo "$pretty_key ::: $pretty_action"

done | \
# Sort alphabetically by the Action
sort | \
# Pipe to Rofi
rofi -dmenu -i -p "Keybinds" -width 60
