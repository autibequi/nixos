#!/usr/bin/env bash
# waybar-resource-bar.sh — Barras azuis no estilo dot-matrix para Waybar (CPU ou RAM)
# Uso: waybar-resource-bar.sh cpu | waybar-resource-bar.sh memory
# Saída: JSON para custom module (return-type: json)

set -euo pipefail

export PATH="/run/current-system/sw/bin:${HOME}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:${PATH:-}"

BLUE="#3498db"
# Cache CPU: /tmp é gravável em qualquer sessão (waybar roda como user)
CPU_PREV="${TMPDIR:-/tmp}/waybar_cpu_prev_${UID:-0}"

# Gauge azul: ícone + número + barra (▓ cheio, ▒ tracejado mesmo azul)
_gauge_blue() {
  local icon="${1:-}" pct="${2:-0}" num w=4 filled seg i
  if (( pct >= 100 )); then
    num="100"
    filled=$w
  else
    num=$(printf '%02d' "$pct")
    filled=$(( pct * w / 100 ))
  fi
  seg=""
  for (( i=0; i<w; i++ )); do (( i < filled )) && seg+="▓" || seg+="▒"; done
  # Padding mínimo à esquerda antes do ícone (hair space U+200A)
  printf '<span background="%s" color="#111111"> %s%s</span><span color="%s">%s</span>' \
    "$BLUE" "$icon" "$num" "$BLUE" "$seg"
}

# RAM: /proc/meminfo
_mem_pct() {
  awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf "%.0f", (t>0 && a!="") ? (t-a)*100/t : 0}' /proc/meminfo
}

# CPU: delta de /proc/stat entre duas leituras (usa cache)
_cpu_pct() {
  local now idle total prev_idle prev_total di dt
  now=$(grep '^cpu ' /proc/stat | awk '{idle=$5; total=$2+$3+$4+$5+$6+$7+$8; print idle, total}')
  read -r idle total <<< "$now"
  if [[ -r "$CPU_PREV" ]]; then
    read -r prev_idle prev_total < "$CPU_PREV"
    di=$(( idle - prev_idle ))
    dt=$(( total - prev_total ))
    if (( dt > 0 )); then
      awk "BEGIN {printf \"%.0f\", 100 * (1 - $di / $dt)}"
    else
      echo "0"
    fi
  else
    echo "0"
  fi
  echo "$now" > "$CPU_PREV"
}

case "${1:-}" in
  cpu)
    pct=$(_cpu_pct)
    text=$(_gauge_blue "󰍛 " "$pct")
    tooltip="CPU: ${pct}%"
    ;;
  memory|mem|ram)
    pct=$(_mem_pct)
    text=$(_gauge_blue "󰘚 " "$pct")
    tooltip="RAM: ${pct}%"
    ;;
  *)
    echo '{"text":"?","tooltip":"usage: cpu | memory","class":""}'
    exit 0
    ;;
esac

# Saída JSON segura (jq quando disponível, senão substituir aspas no text)
if command -v jq &>/dev/null; then
  jq -cn --arg text "$text" --arg tooltip "$tooltip" '{text: $text, tooltip: $tooltip, class: "resource-bar"}'
else
  escaped_text="${text//\"/\\\"}"
  printf '{"text":"%s","tooltip":"%s","class":"resource-bar"}\n' "$escaped_text" "$tooltip"
fi
