#!/bin/bash

# Script custom para mostrar status do TLP no waybar
# Retorna JSON formatado para o waybar

# Função para obter status do TLP
get_tlp_status() {
    local tlp_output=$(tlp-stat -s 2>/dev/null)
    
    # Extrair informações
    local state=$(echo "$tlp_output" | grep "State" | awk '{print $3}')
    local mode=$(echo "$tlp_output" | grep "Mode" | awk '{print $3}')
    local power_source=$(echo "$tlp_output" | grep "Power source" | awk '{print $4}')
    
    # Definir ícones baseados no estado
    local icon=""
    case "$state" in
        "enabled")
            case "$mode" in
                "battery") icon="󰂃" ;;
                "AC") icon="󰂄" ;;
                *) icon="󰂄" ;;
            esac
            ;;
        "disabled")
            icon="󰂃"
            ;;
        *)
            icon=""
            ;;
    esac
    
    # Criar tooltip
    local tooltip="TLP Status\nState: $state\nMode: $mode\nPower: $power_source"
    
    # Retornar JSON para waybar
    echo "{\"text\":\"$icon $state\",\"tooltip\":\"$tooltip\",\"class\":\"$state\"}"
}

# Executar função principal
get_tlp_status 