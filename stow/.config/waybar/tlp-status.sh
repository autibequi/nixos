#!/bin/sh

# Script custom para mostrar status do TLP no waybar
# Retorna JSON formatado para o waybar

# Função para obter status do TLP
get_tlp_status() {
    local tlp_output=$(tlp-stat -s 2>/dev/null)
    local platform_profile=$(cat /sys/firmware/acpi/platform_profile 2>/dev/null || echo "unknown")
    local battery_capacity=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "0")
    local ac_online=$(cat /sys/class/power_supply/AC/online 2>/dev/null || echo "0")
    
    # Extrair informações do TLP
    local state=$(echo "$tlp_output" | grep "State" | awk '{print $3}')
    local mode=$(echo "$tlp_output" | grep "Mode" | awk '{print $3}')
    local power_source=$(echo "$tlp_output" | grep "Power source" | awk '{print $4}')
    
    # Obter informações de performance
    local cpu_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
    local epp_preference=$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null || echo "unknown")
    
    # Definir ícones baseados no estado e modo
    local icon=""
    case "$state" in
        "enabled")
            case "$platform_profile" in
                "performance") icon="󰓅" ;;
                "balanced") icon="󰉎" ;;
                "low-power") icon="󰂃" ;;
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
    
    # Criar texto principal
    local text="$icon $platform_profile"
    if [ "$ac_online" = "0" ]; then
        text="$text $battery_capacity%"
    fi
    
    # Criar tooltip detalhado
    local tooltip="TLP Status\n"
    tooltip="${tooltip}State: $state\n"
    tooltip="${tooltip}Mode: $mode\n"
    tooltip="${tooltip}Power: $power_source\n"
    tooltip="${tooltip}Platform Profile: $platform_profile\n"
    tooltip="${tooltip}CPU Governor: $cpu_governor\n"
    tooltip="${tooltip}EPP: $epp_preference\n"
    if [ "$ac_online" = "0" ]; then
        tooltip="${tooltip}Battery: $battery_capacity%"
    else
        tooltip="${tooltip}AC: Connected"
    fi
    
    # Retornar JSON para waybar
    echo "{\"text\":\"$text\",\"tooltip\":\"$tooltip\",\"class\":\"$state\"}"
}

# Executar função principal
get_tlp_status 