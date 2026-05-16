#!/usr/bin/env bash
# Lista special workspaces (ativos ou com janelas) como pango text pro waybar.
# Saída: JSON {"text": "...", "tooltip": "...", "class": "..."}
#
# Specials no Hyprland têm `id < 0` e `name` começando com "special:".
# Mostramos só os que existem (têm janelas), com cor por nome + ícones de janelas.

set -euo pipefail

WORKSPACES=$(hyprctl -j workspaces)
CLIENTS=$(hyprctl -j clients)
ACTIVE_SPECIAL=$(hyprctl -j activeworkspace | jq -r '.name // ""')

# Mapeamento de cor por short-name (igual ao módulo normal)
declare -A COLORS=(
    [f1]='#b05450'  [f2]='#a87240'  [f3]='#9a8838'  [f4]='#429960'
    [f5]='#369088' [f6]='#4070a8' [f7]='#7058a0'  [f8]='#8040a8'
    [f9]='#8040a8' [f10]='#8040a8'
    [bleh]='#ff79c6' [gemini]='#00d4ff'
)

# Mapeamento class → ícone (subset do window-rewrite do módulo normal)
classify() {
    local class="$1" title="$2"
    case "$class" in
        firefox|Mozilla*)     echo "" ;;
        vivaldi*)              echo "" ;;
        zen*|app.zen_browser*) echo "" ;;
        chrome|chromium|*Chrome*) echo "" ;;
        dbeaver*)              echo "🦫" ;;
        code|Code)             echo "󰨞" ;;
        cursor|Cursor)         echo "󰨞" ;;
        obsidian|Obsidian)     echo "" ;;
        Alacritty|alacritty)   echo "󰆍" ;;
        ghostty|*Ghostty*)     echo "󰆍" ;;
        org.gnome.Nautilus|Nautilus) echo "" ;;
        zed*|Zed*)             echo "󰰶" ;;
        stremio|Stremio)       echo "🍿" ;;
        insomnia|Insomnia)     echo "" ;;
        yaak*|Yaak*)           echo "󰆚" ;;
        steam_app_*|Steam)     echo "󰮯" ;;
        *)
            # Heurística por título
            case "$title" in
                *btop*|*htop*) echo "btop" ;;
                *Gemini*)      echo "󰼙" ;;
                *Meet*)         echo "" ;;
                *YouTube*Music*) echo "" ;;
                *)              echo "" ;;
            esac ;;
    esac
}

# Iterar specials que têm windows OU estão ativos
output=""
parts=()
tooltip_lines=()

while IFS=$'\t' read -r ws_name; do
    [ -z "$ws_name" ] && continue
    short="${ws_name#special:}"
    color="${COLORS[$short]:-#9ca3af}"

    # Janelas desse special
    icons=$(echo "$CLIENTS" | jq -r --arg ws "$ws_name" \
        '.[] | select(.workspace.name == $ws) | "\(.class)\t\(.title)"')

    icons_rendered=""
    win_count=0
    while IFS=$'\t' read -r cls ttl; do
        [ -z "$cls" ] && continue
        ico=$(classify "$cls" "$ttl")
        icons_rendered+=" ${ico}"
        win_count=$((win_count + 1))
    done <<< "$icons"

    # Highlight se ativo
    is_active=false
    [ "$ws_name" = "$ACTIVE_SPECIAL" ] && is_active=true

    # Pango: <span fg='COR' weight='bold'>SHORT:</span> icons
    weight="normal"
    $is_active && weight="bold"
    label="<span foreground='${color}' weight='${weight}'>${short}:</span><span foreground='#e6e6e6'>${icons_rendered}</span>"

    parts+=("$label")
    tooltip_lines+=("${short} (${win_count} janela$( [ "$win_count" != "1" ] && echo s ))")
done < <(echo "$WORKSPACES" | jq -r '.[] | select(.id < 0) | .name')

if [ ${#parts[@]} -eq 0 ]; then
    echo '{"text":"","tooltip":"sem special workspaces","class":"empty"}'
    exit 0
fi

# Junta com espaço
IFS='  ' joined=""
for ((i=0; i<${#parts[@]}; i++)); do
    if [ $i -gt 0 ]; then joined+="  "; fi
    joined+="${parts[$i]}"
done

# Tooltip: lista
tooltip=$(printf '%s\n' "${tooltip_lines[@]}")

# JSON-safe escape (jq cuida)
jq -nc --arg text "$joined" --arg tooltip "$tooltip" \
    '{text: $text, tooltip: $tooltip, class: "special"}'
