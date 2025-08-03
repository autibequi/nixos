escape_workspace() {
    # Função para sair de um workspace especial e ir para o workspace desejado
    local workspace_number="$1"
    local active_special_workspace
    active_special_workspace=$(hyprctl monitors -j | jq -r '.[] | .specialWorkspace.name')
    echo "ACTIVE_SPECIAL_WORKSPACE: $active_special_workspace"
    echo "workspace_number: $workspace_number"

    if [[ "$active_special_workspace" =~ ^special:.*$ ]]; then
        # remove o prefixo special:
        local clean_name
        clean_name=$(echo "$active_special_workspace" | sed 's/^special://')
        echo "clean_name: $clean_name"
        hyprctl dispatch togglespecialworkspace "$clean_name"
    fi

    # move para o workspace passado como argumento
    hyprctl dispatch workspace "$workspace_number"
}

notify-send "Hello, World!"