#!/usr/bin/env bash
# Aplica delta de brilho — atualização otimista via STATE_FILE para feedback imediato.
BUSES_CACHE=/tmp/ddcutil-external-buses
STATE_FILE=/tmp/ddcutil-brightness-state
direction="${1:-up}"

[[ -f "$BUSES_CACHE" ]] || exit 0

# Valor atual: state file (rápido) ou hardware (primeira vez)
if [[ -f "$STATE_FILE" ]]; then
    current=$(cat "$STATE_FILE")
else
    bus=$(head -1 "$BUSES_CACHE")
    current=$(ddcutil getvcp 10 --bus "$bus" --sleep-multiplier 0.1 2>/dev/null \
              | grep -oP 'current value =\s*\K[0-9]+')
    current=${current:-50}
fi

# Calcular novo valor com clamp
if [[ "$direction" == "up" ]]; then
    new_val=$(( current + 5 > 100 ? 100 : current + 5 ))
else
    new_val=$(( current - 5 < 0 ? 0 : current - 5 ))
fi

# Gravar imediatamente — waybar lê isso na hora
echo "$new_val" > "$STATE_FILE"

# Aplicar no hardware em background (não bloqueia o waybar)
while IFS= read -r bus; do
    [[ -z "$bus" ]] && continue
    ddcutil setvcp 10 "$new_val" --bus "$bus" --sleep-multiplier 0.1 &
done < "$BUSES_CACHE"
