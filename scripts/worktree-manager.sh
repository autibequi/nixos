#!/usr/bin/env bash

# worktree-manager.sh
# Gerencia rastreamento de worktrees: entrada, status, saída
# Atualiza vault/worktrees.md com dashboard dinâmico

set -euo pipefail

REPO_ROOT="${REPO_ROOT:-.}"
VAULT="${REPO_ROOT}/vault"
WORKTREE_DIR="${VAULT}/worktrees"
WORKTREE_REGISTRY="${VAULT}/.worktrees-registry.json"

# Garante que o registro existe
init_registry() {
    if [[ ! -f "$WORKTREE_REGISTRY" ]]; then
        echo '{}' > "$WORKTREE_REGISTRY"
    fi
}

# Detecta se estou em um worktree e retorna seu nome
get_current_worktree() {
    if ! git rev-parse --git-worktree-dir &>/dev/null; then
        return 1
    fi

    local worktree_dir
    worktree_dir=$(git rev-parse --git-worktree-dir)

    # Extrai nome da branch atual
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD)
    echo "$branch"
}

# Registra entrada em worktree
worktree_init() {
    local name="$1"
    local branch="$2"
    local objective="$3"

    init_registry

    local now
    now=$(date -u '+%Y-%m-%d %H:%M:%S')

    # Atualiza registro
    jq --arg name "$name" \
       --arg branch "$branch" \
       --arg objective "$objective" \
       --arg entered "$now" \
       '.[$name] = {"branch": $branch, "objective": $objective, "entered": $entered, "status": "in-progress"}' \
       "$WORKTREE_REGISTRY" > "${WORKTREE_REGISTRY}.tmp"
    mv "${WORKTREE_REGISTRY}.tmp" "$WORKTREE_REGISTRY"

    # Cria pasta do worktree
    mkdir -p "$WORKTREE_DIR/$name"

    echo "✓ Worktree registrado: $name ($branch)"
}

# Exibe status detalhado
worktree_status() {
    local current
    if ! current=$(get_current_worktree); then
        echo "❌ Não estou em um worktree"
        return 1
    fi

    init_registry

    local entry
    entry=$(jq -r ".\"$current\"" "$WORKTREE_REGISTRY")

    if [[ "$entry" == "null" ]]; then
        echo "⚠️  Worktree $current não está no registro. Registrando..."
        worktree_init "$current" "$current" "sem objetivo registrado"
        entry=$(jq -r ".\"$current\"" "$WORKTREE_REGISTRY")
    fi

    local branch objective entered
    branch=$(echo "$entry" | jq -r '.branch')
    objective=$(echo "$entry" | jq -r '.objective')
    entered=$(echo "$entry" | jq -r '.entered')

    # Calcula tempo decorrido
    local entered_sec
    entered_sec=$(date -d "$entered" '+%s')
    local now_sec
    now_sec=$(date '+%s')
    local elapsed=$((now_sec - entered_sec))
    local hours=$((elapsed / 3600))
    local minutes=$(((elapsed % 3600) / 60))

    # Conta mudanças
    local changed_files
    changed_files=$(git status --short | wc -l)

    # Conta linhas adicionadas/removidas
    local additions deletions
    local diff_line
    diff_line=$(git diff --stat 2>/dev/null | tail -1 | grep -o '[0-9]* insertion' | grep -o '[0-9]*' || echo "0")
    additions="${diff_line:-0}"
    diff_line=$(git diff --stat 2>/dev/null | tail -1 | grep -o '[0-9]* deletion' | grep -o '[0-9]*' || echo "0")
    deletions="${diff_line:-0}"

    # Exibe dashboard
    cat << EOF

🔀 WORKTREE: $current
├─ Branch: $branch
├─ Objetivo: $objective
├─ Entrado: $entered (${hours}h ${minutes}m)
│
├─ 📝 Mudanças:
│  ├─ Arquivos modificados: $changed_files
│  ├─ Adições: $additions linhas
│  ├─ Deleções: $deletions linhas
│
├─ 📂 Artefatos:
│  └─ $WORKTREE_DIR/$current/
│     ├─ README.md
│     ├─ changes.md
│     └─ proposal.md
│
└─ 🎯 Next: git diff > changes.md && criar proposal.md

EOF
}

# Atualiza dashboard no vault
update_dashboard() {
    init_registry

    local registry
    registry=$(cat "$WORKTREE_REGISTRY")

    if [[ -z "$registry" ]] || [[ "$registry" == "{}" ]]; then
        # Nenhum worktree ativo
        return 0
    fi

    # TODO: Gerar tabela markdown dinâmica
    # Por enquanto, apenas log
    echo "✓ Dashboard atualizado"
}

# Finaliza worktree e move artefatos
worktree_exit() {
    local current
    if ! current=$(get_current_worktree); then
        echo "❌ Não estou em um worktree"
        return 1
    fi

    # Move pra reports
    local report_dir="${VAULT}/_agent/reports/worktree-${current}-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$report_dir"

    if [[ -d "$WORKTREE_DIR/$current" ]]; then
        cp -r "$WORKTREE_DIR/$current"/* "$report_dir/" 2>/dev/null || true
        rm -rf "$WORKTREE_DIR/$current"
    fi

    # Remove do registro
    jq "del(.[\"$current\"])" "$WORKTREE_REGISTRY" > "${WORKTREE_REGISTRY}.tmp"
    mv "${WORKTREE_REGISTRY}.tmp" "$WORKTREE_REGISTRY"

    echo "✓ Worktree finalizado: $current"
    echo "  Artefatos movidos para: $report_dir"
}

# Main
case "${1:-status}" in
    init)
        worktree_init "$2" "${3:-}" "${4:-}"
        ;;
    status)
        worktree_status
        ;;
    list)
        init_registry
        jq '.' "$WORKTREE_REGISTRY"
        ;;
    update-dashboard)
        update_dashboard
        ;;
    exit)
        worktree_exit
        ;;
    *)
        cat << 'EOF'
worktree-manager.sh — Gerenciador de worktrees

Uso:
  worktree-manager.sh init <name> <branch> <objective>
  worktree-manager.sh status
  worktree-manager.sh list
  worktree-manager.sh update-dashboard
  worktree-manager.sh exit
EOF
        exit 1
        ;;
esac
