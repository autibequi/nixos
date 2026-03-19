#!/usr/bin/env bash
# Checa status do serviço obsidian-sync e retorna JSON pro waybar
# Estilo: quadrado colorido (como as barras de CPU/RAM)

set -euo pipefail

PURPLE="#9b59b6"
RED="#e74c3c"
GRAY="#636e72"

VAULT_PATH="/home/pedrinho/.ovault"
CONFIG_PATH="/home/pedrinho/.config/obsidian-headless"
MODULE_PATH="$HOME/nixos/modules/obsidian-sync.nix"

state=$(systemctl is-active obsidian-sync 2>/dev/null || true)

# Mesmo "active", pode ter erros recentes no journal (ex: ENOENT)
has_errors=false
if [[ "$state" == "active" ]]; then
  recent_errors=$(journalctl -u obsidian-sync --since "5 min ago" --no-pager -p err -q 2>/dev/null | tail -3 || true)
  [[ -n "$recent_errors" ]] && has_errors=true
fi

# Contar vaults (subpastas em .ovault)
vault_count=0
vault_list=""
if [[ -d "$VAULT_PATH" ]]; then
  while IFS= read -r d; do
    vault_count=$((vault_count + 1))
    vault_list="${vault_list}  - $(basename "$d")\n"
  done < <(find "$VAULT_PATH" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
fi

# Uptime do serviço
uptime=""
if [[ "$state" == "active" ]]; then
  uptime=$(systemctl show obsidian-sync --property=ActiveEnterTimestamp --value 2>/dev/null || true)
  [[ -n "$uptime" ]] && uptime="Desde: ${uptime}"
fi

# Tooltip
base_tooltip="Obsidian Sync\nPasta: ${VAULT_PATH}\nVaults: ${vault_count}\n${vault_list}${uptime}"

if [[ "$state" == "active" && "$has_errors" == "false" ]]; then
  color="$PURPLE"
  icon="󰄬"
  tooltip="${base_tooltip}\nStatus: OK"
  class="active"
elif [[ "$state" == "active" && "$has_errors" == "true" ]]; then
  color="$RED"
  icon="󰅙"
  tooltip="${base_tooltip}\nStatus: erros recentes\n$(echo "$recent_errors" | tr '\n' ' ' | sed 's/"/\\"/g')"
  class="error"
elif [[ "$state" == "failed" ]]; then
  color="$RED"
  icon="󰅙"
  tooltip="${base_tooltip}\nStatus: FALHOU"
  class="failed"
else
  color="$GRAY"
  icon="󰅙"
  tooltip="${base_tooltip}\nStatus: $state"
  class="inactive"
fi

text="<span background='${color}' color='#111111'> ${icon} </span>"

escaped_tooltip="${tooltip//\\/\\\\}"
escaped_tooltip="${escaped_tooltip//\"/\\\"}"
escaped_tooltip="${escaped_tooltip//$'\n'/\\n}"
printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$escaped_tooltip" "$class"
