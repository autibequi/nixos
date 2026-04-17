#!/usr/bin/env bash
# Painel interativo do Obsidian Sync (abre via waybar on-click)

set -euo pipefail

VAULT_PATH="/home/pedrinho/.ovault"
CONFIG_PATH="/home/pedrinho/.config/obsidian-headless"
MODULE_PATH="$HOME/nixos/modules/obsidian-sync.nix"

PURPLE='\033[0;35m'
RED='\033[0;31m'
GREEN='\033[0;32m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${PURPLE}=== Obsidian Sync ===${NC}"
echo

# Status
state=$(systemctl is-active obsidian-sync 2>/dev/null || true)
case "$state" in
  active) echo -e "Status: ${GREEN}● rodando${NC}" ;;
  failed) echo -e "Status: ${RED}● falhou${NC}" ;;
  *)      echo -e "Status: ${GRAY}● $state${NC}" ;;
esac

# Uptime
if [[ "$state" == "active" ]]; then
  since=$(systemctl show obsidian-sync --property=ActiveEnterTimestamp --value 2>/dev/null || true)
  [[ -n "$since" ]] && echo -e "Desde:  ${since}"
fi
echo

# Pasta sync
echo -e "${BOLD}Pasta:${NC} $VAULT_PATH"
if [[ -d "$VAULT_PATH" ]]; then
  echo -e "${BOLD}Vaults:${NC}"
  for d in "$VAULT_PATH"/*/; do
    [[ -d "$d" ]] && echo -e "  ${PURPLE}$(basename "$d")${NC}"
  done
else
  echo -e "  ${RED}Pasta não existe!${NC}"
fi
echo

# Config
echo -e "${BOLD}Config:${NC} $CONFIG_PATH"
if [[ -d "$CONFIG_PATH" ]]; then
  ls -la "$CONFIG_PATH" 2>/dev/null | tail -n +2
else
  echo -e "  ${GRAY}Nenhuma config encontrada${NC}"
fi
echo

# Módulo NixOS
echo -e "${BOLD}Módulo NixOS:${NC} $MODULE_PATH"
echo

# Erros recentes
echo -e "${BOLD}Erros recentes (10 min):${NC}"
errors=$(journalctl -u obsidian-sync --since "10 min ago" --no-pager -p err -q 2>/dev/null || true)
if [[ -n "$errors" ]]; then
  echo -e "${RED}${errors}${NC}"
else
  echo -e "  ${GREEN}Nenhum erro${NC}"
fi
echo

# Menu
echo -e "${BOLD}Ações:${NC}"
echo "  [l] Logs live (journalctl -f)"
echo "  [r] Restart serviço"
echo "  [s] Stop serviço"
echo "  [e] Editar módulo NixOS"
echo "  [q] Sair"
echo
read -rp "→ " choice

case "$choice" in
  l) journalctl -u obsidian-sync -f ;;
  r) sudo systemctl restart obsidian-sync && echo -e "${GREEN}Reiniciado!${NC}" && sleep 2 ;;
  s) sudo systemctl stop obsidian-sync && echo -e "${RED}Parado.${NC}" && sleep 2 ;;
  e) ${EDITOR:-vim} "$MODULE_PATH" ;;
  q|"") exit 0 ;;
esac
