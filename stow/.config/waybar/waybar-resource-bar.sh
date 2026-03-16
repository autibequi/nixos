#!/usr/bin/env bash
# waybar-resource-bar.sh — Barras azuis no estilo dot-matrix para Waybar (CPU ou RAM)
# Uso: waybar-resource-bar.sh cpu | waybar-resource-bar.sh memory
# Saída: JSON para custom module (return-type: json)
# Cópia em .config/waybar/ para o Waybar achar sem depender de ~/scripts

set -euo pipefail

export PATH="/run/current-system/sw/bin:${HOME}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:${PATH:-}"

BLUE="#3498db"
# Cache CPU: /tmp é gravável em qualquer sessão (waybar roda como user)
CPU_PREV="${TMPDIR:-/tmp}/waybar_cpu_prev_${UID:-0}"

# Gauge azul: ícone + número + barra (▓ cheio, ▒ tracejado mesmo azul)
# Uso: _gauge_blue "󰍛" 45  →  ícone + "45" + barra
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

# Detalhes para tooltip CPU: load, modelo, freq, cores
_cpu_tooltip() {
  local load1 load5 load15
  read -r load1 load5 load15 _ < /proc/loadavg 2>/dev/null || true
  local model=""
  model=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | sed 's/^[^:]*: *//' || echo "?")
  local freq_mhz=""
  if [[ -r /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ]]; then
    freq_mhz=$(($(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null || echo 0) / 1000))
  elif [[ -r /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq ]]; then
    freq_mhz=$(($(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 2>/dev/null || echo 0) / 1000))
  fi
  local cores
  cores=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "?")
  printf "Uso: %s%%\nLoad (1/5/15 min): %s %s %s\nModelo: %s\n" "$1" "${load1:-?}" "${load5:-?}" "${load15:-?}" "$model"
  [[ -n "$freq_mhz" && "$freq_mhz" -gt 0 ]] && printf "Frequência: %s MHz\n" "$freq_mhz"
  printf "Núcleos: %s\n" "$cores"
}

# Achar nvidia-smi (Waybar pode rodar com PATH limitado). Não usar ||/&& que falham com set -e.
_nvidia_smi() {
  if command -v nvidia-smi &>/dev/null; then
    command -v nvidia-smi
    return
  fi
  if [[ -x /run/current-system/sw/bin/nvidia-smi ]]; then
    echo /run/current-system/sw/bin/nvidia-smi
    return
  fi
  if [[ -x /nix/var/nix/profiles/system/sw/bin/nvidia-smi ]]; then
    echo /nix/var/nix/profiles/system/sw/bin/nvidia-smi
  fi
}

# GPU: NVIDIA (nvidia-smi) ou AMD (rocm-smi)
_gpu_pct() {
  local raw="0" pct
  local nvid=$(_nvidia_smi)
  if [[ -n "$nvid" ]]; then
    raw=$("$nvid" --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' ')
    # nvidia-smi pode retornar "N/A" quando a GPU está em baixo consumo (ex.: Prime)
    [[ -z "$raw" || "$raw" == "N/A" || ! "$raw" =~ ^[0-9]+$ ]] && raw="0"
  elif command -v rocm-smi &>/dev/null; then
    raw=$(rocm-smi --showuse 2>/dev/null | grep -oP '\d+(?=%)' | head -1)
    [[ -z "$raw" ]] && raw="0"
  fi
  echo "${raw:-0}"
}

_gpu_tooltip() {
  local nvid=$(_nvidia_smi)
  if [[ -n "$nvid" ]]; then
    local name util mem_used mem_total temp
    name=$("$nvid" --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
    util=$("$nvid" --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' ')
    mem_used=$("$nvid" --query-gpu=memory.used --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' ')
    mem_total=$("$nvid" --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' ')
    temp=$("$nvid" --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' ')
    [[ "$util" == "N/A" || -z "$util" ]] && util="?"
    printf "GPU: %s\nUso: %s%%\nVRAM: %s / %s MiB\n" "$name" "$util" "${mem_used:-?}" "${mem_total:-?}"
    [[ -n "$temp" && "$temp" != "N/A" ]] && printf "Temperatura: %s °C\n" "$temp"
  elif command -v rocm-smi &>/dev/null; then
    rocm-smi --showproductname 2>/dev/null | sed 's/^/GPU: /'
    rocm-smi --showmeminfo vram 2>/dev/null | head -5
    rocm-smi --showtemp 2>/dev/null | head -3
  else
    echo "GPU: não detectada (nvidia-smi/rocm-smi)"
  fi
}

case "${1:-}" in
  cpu)
    pct=$(_cpu_pct)
    text=$(_gauge_blue "󰍛 " "$pct")
    tooltip=$(_cpu_tooltip "$pct")
    ;;
  memory|mem|ram)
    pct=$(_mem_pct)
    text=$(_gauge_blue "󰘚 " "$pct")
    tooltip=$(awk -v pct="$pct" '/MemTotal/{t=$2} /MemAvailable/{a=$2} /MemFree/{f=$2} END{
      printf "RAM: %s%%\nTotal: %.1f GiB\nDisponível: %.1f GiB\nLivre: %.1f GiB\n", pct, t/1024/1024, a/1024/1024, f/1024/1024
    }' /proc/meminfo)
    ;;
  gpu)
    pct=$(_gpu_pct)
    text=$(_gauge_blue "󰢮 " "$pct")
    tooltip=$(_gpu_tooltip)
    ;;
  *)
    echo '{"text":"?","tooltip":"usage: cpu | memory | gpu","class":""}'
    exit 0
    ;;
esac

# Saída JSON segura (jq quando disponível, senão escapar aspas e newlines)
if command -v jq &>/dev/null; then
  jq -cn --arg text "$text" --arg tooltip "$tooltip" '{text: $text, tooltip: $tooltip, class: "resource-bar"}'
else
  escaped_text="${text//\"/\\\"}"
  escaped_tooltip="${tooltip//\\/\\\\}"
  escaped_tooltip="${escaped_tooltip//\"/\\\"}"
  escaped_tooltip="${escaped_tooltip//$'\n'/\\n}"
  printf '{"text":"%s","tooltip":"%s","class":"resource-bar"}\n' "$escaped_text" "$escaped_tooltip"
fi
