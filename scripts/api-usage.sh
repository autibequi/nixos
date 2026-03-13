#!/usr/bin/env bash
# api-usage.sh — Consulta Anthropic Admin API (Usage + Cost)
# Usage: api-usage.sh [--json] [1d|7d|30d]
set -euo pipefail

# ── Config ────────────────────────────────────────────────────────
API_KEY="${ANTHROPIC_ADMIN_KEY:-}"
BASE="https://api.anthropic.com/v1/organizations"
USAGE_EP="${BASE}/usage_report/messages"
COST_EP="${BASE}/cost_report"

if [ -z "$API_KEY" ]; then
  echo "Erro: ANTHROPIC_ADMIN_KEY nao definida."
  echo ""
  echo "  1. Acesse: https://console.anthropic.com/settings/admin-keys"
  echo "  2. Crie uma Admin API key (sk-ant-admin...)"
  echo "  3. Exporte: export ANTHROPIC_ADMIN_KEY='sk-ant-admin...'"
  echo "     ou adicione ao seu .env"
  exit 1
fi

# ── Parse args ────────────────────────────────────────────────────
OUTPUT_JSON=0
PERIOD="1d"
while [ $# -gt 0 ]; do
  case "$1" in
    --json) OUTPUT_JSON=1; shift ;;
    1d|today|7d|30d) PERIOD="$1"; shift ;;
    *) echo "Uso: $0 [--json] [1d|7d|30d]"; exit 1 ;;
  esac
done

# ── Date range ────────────────────────────────────────────────────
# GNU date (-d) com fallback pra BSD date (-v)
_date_ago() {
  local days="$1"
  date -u -d "-${days} days" +%Y-%m-%dT00:00:00Z 2>/dev/null \
    || date -u -v-${days}d +%Y-%m-%dT00:00:00Z
}

END=$(date -u -d "+1 day" +%Y-%m-%dT00:00:00Z 2>/dev/null \
  || date -u -v+1d +%Y-%m-%dT00:00:00Z)

case "$PERIOD" in
  1d|today) START=$(date -u +%Y-%m-%dT00:00:00Z); BUCKET="1h" ;;
  7d)       START=$(_date_ago 7);                  BUCKET="1d" ;;
  30d)      START=$(_date_ago 30);                 BUCKET="1d" ;;
esac

HEADERS=(
  -H "anthropic-version: 2023-06-01"
  -H "x-api-key: ${API_KEY}"
  -H "Content-Type: application/json"
)

# ── Fetch usage (tokens por modelo) ──────────────────────────────
USAGE=$(curl -sS "${USAGE_EP}?starting_at=${START}&ending_at=${END}&bucket_width=${BUCKET}&group_by[]=model" \
  "${HEADERS[@]}" 2>&1)

# ── Fetch cost ────────────────────────────────────────────────────
COST=$(curl -sS "${COST_EP}?starting_at=${START}&ending_at=${END}&bucket_width=1d&group_by[]=description" \
  "${HEADERS[@]}" 2>&1)

# ── JSON output ───────────────────────────────────────────────────
if [ "$OUTPUT_JSON" = "1" ]; then
  echo '{"usage":'
  echo "$USAGE"
  echo ',"cost":'
  echo "$COST"
  echo '}'
  exit 0
fi

# ── Pretty print ─────────────────────────────────────────────────
START_DISPLAY=${START%%T*}
END_DISPLAY=$(date -u +%Y-%m-%d)

echo "  ┌──────────────────────────────────────────────────┐"
echo "  │  APERTURE SCIENCE — API Usage Report ($PERIOD)      │"
echo "  │  Periodo: $START_DISPLAY → $END_DISPLAY                        │"
echo "  │  // the cake is a lie but the bill is real //  │"
echo "  └──────────────────────────────────────────────────┘"
echo ""

# Precisa de jq pra output formatado
if ! command -v jq &>/dev/null; then
  echo "[aviso] jq nao encontrado — mostrando JSON bruto"
  echo ""
  echo "=== Usage ==="
  echo "$USAGE"
  echo ""
  echo "=== Cost ==="
  echo "$COST"
  exit 0
fi

# Verifica erros na resposta
_check_error() {
  local resp="$1" label="$2"
  local err
  err=$(echo "$resp" | jq -r '.error.message // .error.type // empty' 2>/dev/null || true)
  if [ -n "$err" ]; then
    echo "  [ERRO] $label: $err"
    return 1
  fi
  return 0
}

# ── Tokens por modelo ─────────────────────────────────────────────
echo "=== Tokens por Modelo ==="
echo ""

if _check_error "$USAGE" "Usage API"; then
  echo "$USAGE" | jq -r '
    [.data[]? | {
      model: (.model // "unknown"),
      input: (.input_tokens // 0),
      output: (.output_tokens // 0),
      cache_create: (.cache_creation_input_tokens // 0),
      cache_read: (.cache_read_input_tokens // 0)
    }]
    | group_by(.model)
    | map({
        model: .[0].model,
        input: (map(.input) | add),
        output: (map(.output) | add),
        cache_create: (map(.cache_create) | add),
        cache_read: (map(.cache_read) | add)
      })
    | sort_by(-.input - .output)
    | .[] |
    "  \(.model)\n    Input:         \(.input | tostring | explode | reverse | [range(0;length;3) as $i | .[($i):($i+3)]] | map(implode) | reverse | join(",")) tokens\n    Output:        \(.output | tostring | explode | reverse | [range(0;length;3) as $i | .[($i):($i+3)]] | map(implode) | reverse | join(",")) tokens\n    Cache create:  \(.cache_create | tostring | explode | reverse | [range(0;length;3) as $i | .[($i):($i+3)]] | map(implode) | reverse | join(",")) tokens\n    Cache read:    \(.cache_read | tostring | explode | reverse | [range(0;length;3) as $i | .[($i):($i+3)]] | map(implode) | reverse | join(",")) tokens"
  ' 2>/dev/null || echo "  (sem dados de usage)"
fi

echo ""

# ── Totais de tokens ──────────────────────────────────────────────
echo "=== Totais ==="
echo ""

echo "$USAGE" | jq -r '
  [.data[]?] |
  if length == 0 then "  (sem dados)"
  else
    {
      input: (map(.input_tokens // 0) | add),
      output: (map(.output_tokens // 0) | add),
      cache_create: (map(.cache_creation_input_tokens // 0) | add),
      cache_read: (map(.cache_read_input_tokens // 0) | add)
    } |
    "  Input total:         \(.input) tokens\n  Output total:        \(.output) tokens\n  Cache create total:  \(.cache_create) tokens\n  Cache read total:    \(.cache_read) tokens"
  end
' 2>/dev/null || echo "  (erro ao calcular totais)"

echo ""

# ── Custo ─────────────────────────────────────────────────────────
echo "=== Custo (USD) ==="
echo ""

if _check_error "$COST" "Cost API"; then
  echo "$COST" | jq -r '
    [.data[]? | {
      desc: (.description // "unknown"),
      cost: ((.cost // "0") | tonumber)
    }]
    | group_by(.desc)
    | map({
        desc: .[0].desc,
        cost: (map(.cost) | add)
      })
    | sort_by(-.cost)
    | if length == 0 then ["  (sem dados de custo)"]
      else
        (map("  \(.desc): $\(.cost / 100 | . * 100 | round / 100 | tostring)"))
        + ["", "  Total: $\(map(.cost) | add / 100 | . * 100 | round / 100 | tostring)"]
      end
    | .[]
  ' 2>/dev/null || echo "  (sem dados de custo)"
fi

echo ""
