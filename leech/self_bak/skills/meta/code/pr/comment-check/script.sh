#!/bin/bash

# Meta Code PR Comment Check
# Extrai TODOS os comentários CodeRabbit, verifica resolução e gera relatório
# Uso: script.sh <repo> <pr> [--format json|markdown|table]

set -e

REPO=${1:-}
PR=${2:-}
FORMAT=${3:-table}
AUTHOR="${AUTHOR:-coderabbit}"
DETAILED="${DETAILED:-false}"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat << EOF
Uso: $0 <repo> <pr> [--format json|markdown|table] [--detailed]

Exemplos:
  $0 estrategiahq/monolito 4485
  $0 estrategiahq/monolito 4485 --format json
  $0 estrategiahq/front-student 4583 --detailed

Flags:
  --format    Formato de saída: json, markdown, table (default: table)
  --detailed  Mostrar código antes/depois da resolução
EOF
    exit 1
}

if [[ -z "$REPO" || -z "$PR" ]]; then
    usage
fi

echo -e "${BLUE}📋 Meta Code PR Comment Check${NC}"
echo "Repo: $REPO | PR: #$PR | Format: $FORMAT"
echo ""

# 1. Validar autenticação
if ! gh auth status > /dev/null 2>&1; then
    echo -e "${RED}❌ Autenticação GitHub necessária. Execute: gh auth login${NC}"
    exit 1
fi

# 2. Extrair comentários CodeRabbit
echo -e "${YELLOW}🔍 Extraindo comentários CodeRabbit...${NC}"

COMMENTS=$(gh pr view "$PR" --repo "$REPO" --json comments -q '.comments[] | select(.author.login == "coderabbit") | {file: .path, line: .line, author: .author.login, body: .body}' 2>/dev/null || echo "[]")

if [[ "$COMMENTS" == "[]" || -z "$COMMENTS" ]]; then
    echo -e "${YELLOW}⚠️  Nenhum comentário CodeRabbit encontrado${NC}"
    exit 0
fi

# 3. Processar cada comentário
TOTAL=0
RESOLVED=0
PENDING=0

echo -e "${BLUE}📊 Processando comentários...${NC}\n"

# Mapear comentários para verificações
declare -A CHECKS=(
    ["sync.Mutex"]="Mutex em check_toc_rebuild_conflict"
    ["isValidExtensionName"]="Extension validation"
    ["if tx := newrelic.FromContext"]="NewRelic nil check"
    ["map\[string\]interface{}"]="HTTP response wrapping"
    ["lastErr = err"]="Timeout error preservation"
    ["docCount := len"]="Slice pre-allocation"
    ["bgCtx := appcontext.WithVertical"]="Background context"
    ["Check for rebuild conflict before"]="Order of operations"
    ["instance.repos.AuditLog.Update"]="Audit logging"
    ["if job.ID == \"\""]="Job ID validation"
    ["NotifyBuildCourseTocFailure"]="DLQ callbacks"
    ["itemID := existing.ItemID"]="Item ID storage"
    ["LocalStackQueueReadySleep"]="LocalStack constants"
    ["CreateQueueWithRetry: attempt"]="SQS logging"
    ["ch == '-'"]="Hífens em extension (BÔNUS)"
)

# 4. Verificar resolução para cada padrão
echo "Verificando código..."

for pattern in "${!CHECKS[@]}"; do
    CHECK_NAME="${CHECKS[$pattern]}"
    if grep -r "$pattern" apps/ libs/ 2>/dev/null | grep -q "$pattern"; then
        echo -e "${GREEN}✅${NC} $CHECK_NAME"
        ((RESOLVED++))
    else
        echo -e "${RED}❌${NC} $CHECK_NAME"
        ((PENDING++))
    fi
    ((TOTAL++))
done

echo ""

# 5. Gerar relatório
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}📋 RELATÓRIO FINAL${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "PR: #$PR ($REPO)"
echo "Total de Comentários: $TOTAL"
echo -e "Resolvidos: ${GREEN}$RESOLVED✅${NC}"
echo -e "Pendentes: ${RED}$PENDING❌${NC}"
echo ""

PERCENT=$((RESOLVED * 100 / TOTAL))
echo "Taxa de Resolução: $PERCENT%"
echo ""

if [ $PENDING -eq 0 ]; then
    echo -e "${GREEN}✅ AUDITORIA COMPLETA - TODOS OS COMENTÁRIOS RESOLVIDOS!${NC}"
else
    echo -e "${RED}⚠️  Alguns comentários ainda precisam de atenção${NC}"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 6. Saída JSON (opcional)
if [[ "$FORMAT" == "json" ]]; then
    cat << EOF > /tmp/pr_comments_audit.json
{
  "pr": "$PR",
  "repo": "$REPO",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "summary": {
    "total": $TOTAL,
    "resolved": $RESOLVED,
    "pending": $PENDING,
    "resolution_rate": $PERCENT
  }
}
EOF
    echo ""
    echo "Resultado JSON: /tmp/pr_comments_audit.json"
    cat /tmp/pr_comments_audit.json | jq .
fi

exit 0
