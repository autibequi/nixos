#!/bin/sh

# Script para alternar entre modos de performance do TLP
# Alterna entre: low-power -> balanced -> performance -> low-power

# Obter perfil atual
current_profile=$(cat /sys/firmware/acpi/platform_profile 2>/dev/null || echo "low-power")

# Definir próximo perfil
case "$current_profile" in
    "low-power")
        next_profile="balanced"
        ;;
    "balanced")
        next_profile="performance"
        ;;
    "performance")
        next_profile="low-power"
        ;;
    *)
        next_profile="balanced"
        ;;
esac

# Aplicar novo perfil (requer sudo)
echo "$next_profile" | sudo tee /sys/firmware/acpi/platform_profile >/dev/null 2>&1

# Notificar mudança
notify-send "TLP Profile" "Switched to $next_profile mode" -t 2000

# Executar TLP para aplicar configurações
sudo tlp start >/dev/null 2>&1 