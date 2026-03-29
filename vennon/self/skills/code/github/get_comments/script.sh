#!/bin/bash
set -euo pipefail

# code/github:get_comments — Extrair comentários de PR
# Autor: Claude Haiku
# Data: 2026-03-27

REPO="${1:-}"
PR="${2:-}"
FORMAT="table"
AUTHOR=""
SEVERITY=""
OUTPUT=""
PATH_FILTER=""
RESOLVED=false
COUNT_ONLY=false

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Severidades com cores
CRITICAL='🔴'
MAJOR='🟠'
MINOR='🟡'
TRIVIAL='🔵'

usage() {
    cat << EOF
${BLUE}code/github:get_comments${NC} — Extrair comentários de PR

${GREEN}Uso:${NC}
  $0 <repo> <pr_number> [options]

${GREEN}Exemplos:${NC}
  $0 estrategiahq/monolito 4485
  $0 estrategiahq/monolito 4485 --author coderabbitai[bot] --format json
  $0 estrategiahq/front-student 4583 --severity critical,major
  $0 estrategiahq/monolito 4485 --output /tmp/comments.json

${GREEN}Opções:${NC}
  --author <name>        Filtrar por autor (ex: coderabbitai[bot])
  --severity <list>      Filtrar por severidade (critical,major,minor,trivial)
  --format <type>        Formato: table|json|markdown|csv (default: table)
  --output <file>        Salvar em arquivo
  --path <glob>          Filtrar por arquivo (glob pattern)
  --resolved             Incluir comentários resolvidos
  --count-only           Retornar só contagem

${GREEN}Formatos:${NC}
  table                  Tabela formatada (padrão)
  json                   JSON estruturado
  markdown               Markdown formatado
  csv                    CSV para análise

EOF
    exit 1
}

# Parse args
while [[ $# -gt 2 ]]; do
    case "$3" in
        --author) AUTHOR="$4"; shift 2 ;;
        --severity) SEVERITY="$4"; shift 2 ;;
        --format) FORMAT="$4"; shift 2 ;;
        --output) OUTPUT="$4"; shift 2 ;;
        --path) PATH_FILTER="$4"; shift 2 ;;
        --resolved) RESOLVED=true; shift ;;
        --count-only) COUNT_ONLY=true; shift ;;
        *) echo "Opção desconhecida: $3"; usage ;;
    esac
done

if [[ -z "$REPO" || -z "$PR" ]]; then
    usage
fi

# Validar token
if [[ ! -f "$HOME/.vennon" ]]; then
    echo -e "${RED}❌ Token não encontrado em ~/.vennon${NC}"
    echo "Configure com: gh auth login"
    exit 1
fi

export GH_TOKEN=$(grep '^GH_TOKEN=' "$HOME/.vennon" | cut -d'=' -f2 || echo "")
if [[ -z "$GH_TOKEN" ]]; then
    echo -e "${RED}❌ GH_TOKEN não encontrado em ~/.vennon${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Extraindo comentários de PR${NC}"
echo "Repo: $REPO | PR: #$PR"
echo ""

# Extrair comentários
COMMENTS=$(gh api repos/"$REPO"/pulls/"$PR"/comments --paginate 2>&1 || echo "[]")

if [[ "$COMMENTS" == "[]" || -z "$COMMENTS" ]]; then
    echo -e "${YELLOW}⚠️  Nenhum comentário encontrado${NC}"
    exit 0
fi

# Parser de severidade
detect_severity() {
    local body="$1"
    if echo "$body" | grep -qi "critical\|panic\|data race\|nil pointer\|sql injection"; then
        echo "CRITICAL"
    elif echo "$body" | grep -qi "major\|should\|must\|deprecated"; then
        echo "MAJOR"
    elif echo "$body" | grep -qi "minor\|could\|consider\|optional"; then
        echo "MINOR"
    else
        echo "TRIVIAL"
    fi
}

# Processar comentários
process_comments() {
    echo "$COMMENTS" | jq -r '.[] |
        {
            id: .id,
            path: .path,
            line: .line,
            author: .user.login,
            created_at: .created_at,
            body: .body
        }' | jq -s '.' | jq -r '.[] |
        "\(.path)|\(.line)|\(.author)|\(.created_at)|\(.body)"' | while IFS='|' read -r path line author created_at body; do

        # Filtrar por autor
        if [[ -n "$AUTHOR" && "$author" != "$AUTHOR" ]]; then
            continue
        fi

        # Filtrar por path
        if [[ -n "$PATH_FILTER" ]]; then
            if ! [[ "$path" == $PATH_FILTER ]]; then
                continue
            fi
        fi

        # Detectar severidade e filtrar
        severity=$(detect_severity "$body")
        if [[ -n "$SEVERITY" ]]; then
            if ! echo "$SEVERITY" | grep -q "$severity"; then
                continue
            fi
        fi

        # Output formatado
        echo "$severity|$path|$line|$author|$created_at|$body"
    done
}

# Gerar output
generate_table() {
    local data="$1"

    echo "┌────────────────────────────────────────────────────────────┐"
    echo "│ PR #$PR — $(echo "$data" | wc -l) comentários                         │"
    echo "├────────────────────────────────────────────────────────────┤"

    echo "$data" | while IFS='|' read -r severity path line author created_at body; do
        body_short=$(echo "$body" | sed 's/[[:space::]]\+/ /g' | cut -c1-60)
        echo "│ [$severity] $path:$line"
        echo "│ $body_short"
        echo "│ Author: $author | $created_at"
        echo "│"
    done | head -100

    echo "└────────────────────────────────────────────────────────────┘"
}

generate_json() {
    local data="$1"

    echo "{"
    echo "  \"repo\": \"$REPO\","
    echo "  \"pr\": $PR,"
    echo "  \"total\": $(echo "$data" | wc -l),"
    echo "  \"comments\": ["

    echo "$data" | while IFS='|' read -r severity path line author created_at body; do
        # Escape JSON
        body_escaped=$(echo "$body" | jq -Rs .)
        echo "    {"
        echo "      \"severity\": \"$severity\","
        echo "      \"path\": \"$path\","
        echo "      \"line\": $line,"
        echo "      \"author\": \"$author\","
        echo "      \"created_at\": \"$created_at\","
        echo "      \"body\": $body_escaped"
        echo "    },"
    done | sed '$ s/,$//'

    echo "  ]"
    echo "}"
}

generate_markdown() {
    local data="$1"

    echo "# PR #$PR — Comentários ($(echo "$data" | wc -l) total)"
    echo ""

    # Agrupar por severidade
    for sev in "CRITICAL" "MAJOR" "MINOR" "TRIVIAL"; do
        sev_icon=$([[ "$sev" == "CRITICAL" ]] && echo "🔴" || [[ "$sev" == "MAJOR" ]] && echo "🟠" || [[ "$sev" == "MINOR" ]] && echo "🟡" || echo "🔵")
        count=$(echo "$data" | grep "^$sev|" | wc -l)

        if [[ $count -gt 0 ]]; then
            echo "## $sev_icon $sev ($count)"
            echo ""

            echo "$data" | grep "^$sev|" | while IFS='|' read -r severity path line author created_at body; do
                echo "### $path:$line"
                echo ""
                echo "- **Autor**: @$author"
                echo "- **Data**: $created_at"
                echo ""
                echo "$body"
                echo ""
                echo "---"
                echo ""
            done
        fi
    done
}

generate_csv() {
    local data="$1"

    echo "severity,path,line,author,created_at,body"
    echo "$data" | while IFS='|' read -r severity path line author created_at body; do
        body_csv=$(echo "$body" | tr '\"' "'")
        echo "\"$severity\",\"$path\",\"$line\",\"$author\",\"$created_at\",\"$body_csv\""
    done
}

# Processar
PROCESSED=$(process_comments)
TOTAL=$(echo "$PROCESSED" | wc -l)

if [[ $TOTAL -eq 0 ]]; then
    echo -e "${YELLOW}⚠️  Nenhum comentário corresponde aos filtros${NC}"
    exit 0
fi

# Gerar output
case "$FORMAT" in
    json) OUTPUT_DATA=$(generate_json "$PROCESSED") ;;
    markdown) OUTPUT_DATA=$(generate_markdown "$PROCESSED") ;;
    csv) OUTPUT_DATA=$(generate_csv "$PROCESSED") ;;
    table) OUTPUT_DATA=$(generate_table "$PROCESSED") ;;
    *) echo "Formato desconhecido: $FORMAT"; exit 1 ;;
esac

# Salvar ou exibir
if [[ -n "$OUTPUT" ]]; then
    echo "$OUTPUT_DATA" > "$OUTPUT"
    echo -e "${GREEN}✅ Comentários salvos em: $OUTPUT${NC}"
else
    echo "$OUTPUT_DATA"
fi

echo ""
echo -e "${GREEN}✅ Extracted $TOTAL comments${NC}"
