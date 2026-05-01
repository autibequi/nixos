#!/usr/bin/env bash
# Aplica delta de brilho em todos os monitores externos cacheados.
BUSES_CACHE=/tmp/ddcutil-external-buses
direction="${1:-up}"

[[ -f "$BUSES_CACHE" ]] || exit 0
while IFS= read -r bus; do
    [[ -z "$bus" ]] && continue
    if [[ "$direction" == "up" ]]; then
        ddcutil setvcp 10 + 5 --bus "$bus" --sleep-multiplier 0.1
    else
        ddcutil setvcp 10 - 5 --bus "$bus" --sleep-multiplier 0.1
    fi
done < "$BUSES_CACHE"
