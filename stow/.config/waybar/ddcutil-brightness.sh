#!/usr/bin/env bash
# Brightness de monitores externos via DDC/CI.
# Fast path: se o state file foi atualizado há menos de 3s (scroll recente), usa direto.
# Slow path: detecta buses, filtra skiplist, consulta hardware.

SKIPLIST=(
    "TL140ADXP02-0"  # ASUS Zephyrus G14 internal (TMX)
)

BUSES_CACHE=/tmp/ddcutil-external-buses
STATE_FILE=/tmp/ddcutil-brightness-state

is_skipped() {
    local model="$1"
    for skip in "${SKIPLIST[@]}"; do
        [[ "$model" == "$skip" ]] && return 0
    done
    return 1
}

# Fast path — scroll acabou de acontecer, valor já está no state file
if [[ -f "$STATE_FILE" ]]; then
    age=$(( $(date +%s) - $(stat -c %Y "$STATE_FILE") ))
    if (( age < 3 )); then
        val=$(cat "$STATE_FILE")
        echo "{\"text\":\"󰍹 ${val}%\",\"tooltip\":\"Brilho externo: ${val}%\",\"class\":\"\"}"
        exit 0
    fi
fi

# Slow path — detecta buses e consulta hardware
declare -A bus_to_model
current_bus=""
while IFS= read -r line; do
    if [[ "$line" =~ /dev/i2c-([0-9]+) ]]; then
        current_bus="${BASH_REMATCH[1]}"
    elif [[ -n "$current_bus" && "$line" =~ Model:[[:space:]]+(.+) ]]; then
        bus_to_model[$current_bus]="$(echo "${BASH_REMATCH[1]}" | xargs)"
    fi
done < <(ddcutil detect 2>/dev/null)

output_parts=()
valid_buses=()

for bus in $(echo "${!bus_to_model[@]}" | tr ' ' '\n' | sort -n); do
    is_skipped "${bus_to_model[$bus]}" && continue
    val=$(ddcutil getvcp 10 --bus "$bus" --sleep-multiplier 0.1 2>/dev/null \
          | grep -oP 'current value =\s*\K[0-9]+')
    [[ -z "$val" ]] && continue
    output_parts+=("󰍹 ${val}%")
    valid_buses+=("$bus")
    echo "$val" > "$STATE_FILE"  # sincroniza state com hardware real
done

printf '%s\n' "${valid_buses[@]}" > "$BUSES_CACHE"

if [[ ${#output_parts[@]} -eq 0 ]]; then
    echo '{"text":"","tooltip":"Nenhum monitor externo","class":"disconnected"}'
else
    text=$(IFS=" | "; echo "${output_parts[*]}")
    echo "{\"text\":\"${text}\",\"tooltip\":\"Brilho externo\",\"class\":\"\"}"
fi
