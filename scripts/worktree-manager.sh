#!/usr/bin/env bash

# worktree-manager.sh
# Gerencia rastreamento de worktrees: entrada, status, saída
# Atualiza vault/worktrees.md com dashboard dinâmico

set -euo pipefail

REPO_ROOT="${REPO_ROOT:-.}"
VAULT="${REPO_ROOT}/vault"
WORKTREE_DIR="${VAULT}/worktrees"
WORKTREE_REGISTRY="${VAULT}/.worktrees-registry.json"
WORKTREE_LOG="${VAULT}/.worktrees-log.jsonl"
CURRENT_WORKTREE="${CLAU_CURRENT_WORKTREE:-}"  # Set by runner quando lança

# Garante que os arquivos existem
init_registry() {
    if [[ ! -f "$WORKTREE_REGISTRY" ]]; then
        echo '{}' > "$WORKTREE_REGISTRY"
    fi
    if [[ ! -f "$WORKTREE_LOG" ]]; then
        touch "$WORKTREE_LOG"
    fi
}

# Adiciona evento ao log append-only (JSONL - uma linha por evento)
log_event() {
    local event_type="$1"  # enter/exit/update
    local name="$2"
    local branch="$3"
    local objective="${4:-}"
    local worker_id="${CLAU_WORKER_ID:-manual}"

    local timestamp
    timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    # Compact JSON em uma linha
    local event
    event=$(printf '{"timestamp":"%s","type":"%s","name":"%s","branch":"%s","objective":"%s","worker":"%s"}' \
        "$timestamp" "$event_type" "$name" "$branch" "$objective" "$worker_id")

    echo "$event" >> "$WORKTREE_LOG"
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

# Cria arquivo de workbench em main
worktree_create_workbench_summary() {
    local name="$1"
    local branch="$2"
    local objective="$3"
    local now
    now=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    mkdir -p "$REPO_ROOT/workbench"
    local dest="$REPO_ROOT/workbench/${name}.md"

    # Não sobrescrever se já existe
    if [[ -f "$dest" ]]; then
        return 0
    fi

    cat > "$dest" << EOF
---
task: ${name}
branch: ${branch}
created: ${now}
status: in-progress
artefacts: vault/artefacts/${name}/
---

# ${name}

## Resumo
${objective}

## Artefatos
(a preencher)

## Branch
\`${branch}\` — ativa
EOF
    echo "✓ Workbench criado: workbench/${name}.md"
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

    # Log do evento
    log_event "enter" "$name" "$branch" "$objective"

    # Cria workbench summary em main
    worktree_create_workbench_summary "$name" "$branch" "$objective"

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
    # Tenta detectar pela env var primeiro (caso de workers), depois pelo git
    if [[ -n "$CURRENT_WORKTREE" ]]; then
        current="$CURRENT_WORKTREE"
    elif ! current=$(get_current_worktree); then
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

    # Log do evento
    log_event "exit" "$current" "" ""

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
    workers|--workers)
        init_registry
        echo "📊 Histórico: Workers Lançaram Worktrees"
        echo ""
        if [[ -f "$WORKTREE_LOG" ]] && [[ -s "$WORKTREE_LOG" ]]; then
            tail -20 "$WORKTREE_LOG" | while IFS= read -r line; do
                [[ -z "$line" ]] && continue

                timestamp=$(echo "$line" | jq -r '.timestamp // empty' 2>/dev/null)
                type=$(echo "$line" | jq -r '.type // empty' 2>/dev/null)
                name=$(echo "$line" | jq -r '.name // empty' 2>/dev/null)
                worker=$(echo "$line" | jq -r '.worker // empty' 2>/dev/null)

                [[ -z "$timestamp" ]] && continue

                if [[ "$type" == "enter" ]]; then
                    echo "📍 $timestamp | $worker"
                    echo "   ├─ Entrou: $name"
                elif [[ "$type" == "exit" ]]; then
                    echo "   └─ Saiu: $name"
                fi
            done
        else
            echo "Nenhum evento registrado ainda."
        fi
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
