#!/usr/bin/env bash
# Checa status do serviço obsidian-sync e retorna JSON pro waybar
# Estilo: quadrado colorido (como as barras de CPU/RAM)

set -euo pipefail

PURPLE="#9b59b6"
RED="#e74c3c"
GRAY="#636e72"

VAULT_PATH="/home/pedrinho/.ovault"

state=$(systemctl is-active obsidian-sync 2>/dev/null || true)

# Mesmo "active", pode ter erros recentes no journal
has_errors=false
if [[ "$state" == "active" ]]; then
  recent_errors=$(journalctl -u obsidian-sync --since "5 min ago" --no-pager -p err -q 2>/dev/null | tail -1 || true)
  [[ -n "$recent_errors" ]] && has_errors=true
fi

# Últimos arquivos modificados no vault (proxy de "arquivos sincados")
recent_files=""
if [[ -d "$VAULT_PATH" ]]; then
  recent_files=$(find "$VAULT_PATH" -type f -name '*.md' -mmin -60 -printf '%T+ %P\n' 2>/dev/null | sort -r | head -8 | sed 's/^[^ ]* /  /' || true)
fi

# Uptime
uptime=""
if [[ "$state" == "active" ]]; then
  uptime=$(systemctl show obsidian-sync --property=ActiveEnterTimestamp --value 2>/dev/null || true)
fi

# Vaults (subpastas)
vaults=""
if [[ -d "$VAULT_PATH" ]]; then
  vaults=$(find "$VAULT_PATH" -mindepth 1 -maxdepth 1 -type d -printf '  %f\n' 2>/dev/null || true)
fi

# Montar tooltip
tooltip="Obsidian Sync"
tooltip="${tooltip}\nPasta: ${VAULT_PATH}"
[[ -n "$vaults" ]] && tooltip="${tooltip}\nVaults:\n${vaults}"
[[ -n "$uptime" ]] && tooltip="${tooltip}\nDesde: ${uptime}"

if [[ "$state" == "active" && "$has_errors" == "false" ]]; then
  color="$PURPLE"
  icon="✔"
  tooltip="${tooltip}\nStatus: OK"
  class="active"
  if [[ -n "$recent_files" ]]; then
    tooltip="${tooltip}\n\nÚltimos arquivos (1h):\n${recent_files}"
  else
    tooltip="${tooltip}\n\nNenhum arquivo modificado na última hora"
  fi
elif [[ "$state" == "active" && "$has_errors" == "true" ]]; then
  color="$RED"
  icon="✖"
  err_short=$(echo "$recent_errors" | grep -oP 'path: .*' | head -1 || echo "$recent_errors")
  tooltip="${tooltip}\nStatus: erros recentes\n${err_short}"
  class="error"
elif [[ "$state" == "failed" ]]; then
  color="$RED"
  icon="✖"
  tooltip="${tooltip}\nStatus: FALHOU"
  class="failed"
else
  color="$GRAY"
  icon="⏸"
  tooltip="${tooltip}\nStatus: $state"
  class="inactive"
fi

text="<span background='${color}' color='#111111'> ${icon} </span>"

# Escapar pra JSON
escaped_tooltip="${tooltip//\\/\\\\}"
escaped_tooltip="${escaped_tooltip//\"/\\\"}"
escaped_tooltip="${escaped_tooltip//$'\n'/\\n}"
printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$escaped_tooltip" "$class"
