#!/bin/bash
# Status line com deteccao automatica de topico via ultima msg do user
# Recebe JSON do Claude Code: model, workspace, context_window, cost, session_id, worktree, etc.
# Output stdout: status line visivel (plain text; widget nao interpreta ANSI)
# Output stderr: terminal title (OSC) pro Hyprland/waybar
# Debug: DEBUG_STATUSLINE=1 salva o JSON em .ephemeral/statusline-input.json

input=$(cat)

# Debug: dump JSON para inspecao
if [[ -n "${DEBUG_STATUSLINE:-}" ]]; then
  echo "$input" > "${WS:-/workspace}/.ephemeral/statusline-input.json" 2>/dev/null || true
fi

# Dados do JSON (schema: code.claude.com/docs/en/statusline)
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
MODEL_SIZE=$(echo "$MODEL" | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]')

CTX_PCT=$(echo "$input"     | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
CTX_SIZE=$(echo "$input"    | jq -r '.context_window.context_window_size // 0')
EXCEEDS=$(echo "$input"     | jq -r '.exceeds_200k_tokens // false')

# Tokens de input (contexto atual)
CTX_USED=$(echo "$input" | jq -r '
  if .context_window.current_usage then
    (.context_window.current_usage.input_tokens // 0) +
    (.context_window.current_usage.cache_creation_input_tokens // 0) +
    (.context_window.current_usage.cache_read_input_tokens // 0)
  else
    (if .context_window.context_window_size > 0 and .context_window.used_percentage then
      (.context_window.context_window_size * (.context_window.used_percentage / 100)) | floor
     else 0 end)
  end
')

# Cache: tokens lidos do cache vs total de input
CACHE_READ=$(echo "$input"   | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
CACHE_CREATE=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
INPUT_FRESH=$(echo "$input"  | jq -r '.context_window.current_usage.input_tokens // 0')
TOTAL_IN=$(( INPUT_FRESH + CACHE_CREATE + CACHE_READ ))
CACHE_HIT_PCT=0
[[ $TOTAL_IN -gt 0 ]] && CACHE_HIT_PCT=$(( CACHE_READ * 100 / TOTAL_IN ))

# Output tokens acumulados na sessao
OUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

TRANSCRIPT=$(echo "$input"    | jq -r '.transcript_path // ""')
WORKSPACE_DIR=$(echo "$input" | jq -r '.workspace.project_dir // .workspace.current_dir // .cwd // ""')
COST_USD=$(echo "$input"      | jq -r '.cost.total_cost_usd // 0')
COST_DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
LINES_ADDED=$(echo "$input"   | jq -r '.cost.total_lines_added // 0')
LINES_REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
WORKTREE_NAME=$(echo "$input" | jq -r '.worktree.name // .worktree.branch // ""')

# Topico da ultima mensagem do user
TOPIC=""
if [[ -n "$TRANSCRIPT" && -f "$TRANSCRIPT" ]]; then
  TOPIC=$(grep '"role":"user"' "$TRANSCRIPT" 2>/dev/null \
    | tail -1 \
    | jq -r '
      .message.content
      | if type == "string" then .
        elif type == "array" then
          map(select(.type == "text") | .text) | join(" ")
        else ""
        end
    ' 2>/dev/null)
fi
if [[ -z "$TOPIC" || "$TOPIC" == "null" ]]; then
  TOPIC="nova sessao"
fi
TOPIC=$(echo "$TOPIC" | tr '\n' ' ' | sed 's/  */ /g' | head -c 40 | sed 's/[[:space:]]*$//')
[[ ${#TOPIC} -ge 40 ]] && TOPIC="${TOPIC:0:37}..."

# Workers ativos (sessoes zion_ e puppy_)
WORKERS=0
BOCECHAS=0
WS="${WORKSPACE_DIR:-/workspace}"
AGENTS_DIR="/workspace/nixos/.ephemeral/agents"
LIVE_MAX_AGE=900
if [[ -d "$AGENTS_DIR" ]]; then
  now_sec=$(date +%s)
  for dir in "$AGENTS_DIR"/zion_*/ "$AGENTS_DIR"/puppy_*/; do
    [[ "$dir" == *"*"* ]] && continue
    [[ -d "$dir" ]] || continue
    [[ -f "$dir/.live" ]] || continue
    mod=$(stat -c %Y "$dir/.live" 2>/dev/null || echo 0)
    [[ $(( now_sec - mod )) -le $LIVE_MAX_AGE ]] && WORKERS=$(( WORKERS + 1 ))
  done
fi
RUNNING_DIR="$WS/obsidian/_agent/tasks/running"
if [[ -d "$RUNNING_DIR" ]]; then
  now_epoch=$(date +%s)
  for dir in "$RUNNING_DIR"/*/; do
    [[ "$dir" == *"*"* ]] && continue
    [[ -d "$dir" ]] || continue
    [[ -f "$dir/.lock" ]] || continue
    started=$(grep '^started=' "$dir/.lock" 2>/dev/null | cut -d= -f2)
    timeout=$(grep '^timeout=' "$dir/.lock" 2>/dev/null | cut -d= -f2)
    [[ -z "$started" || -z "$timeout" ]] && continue
    start_epoch=$(date -d "$started" +%s 2>/dev/null || echo 0)
    [[ -z "$start_epoch" || "$start_epoch" -eq 0 ]] && continue
    end_epoch=$(( start_epoch + timeout ))
    [[ $now_epoch -lt $end_epoch ]] && BOCECHAS=$(( BOCECHAS + 1 ))
  done
fi

# Formatacao de tokens
fmt_tokens() {
  local n="${1:-0}"
  if   [[ "$n" -ge 1000000 ]]; then echo "$(( n / 1000000 ))M"
  elif [[ "$n" -ge 1000    ]]; then echo "$(( n / 1000 ))k"
  else echo "$n"; fi
}
CTX_SIZE_FMT=$(fmt_tokens "$CTX_SIZE")
CTX_USED_K=$(( CTX_USED / 1000 ))
OUT_TOKENS_FMT=$(fmt_tokens "$OUT_TOKENS")

# --- Barras ---

# Contexto combinado: █ input  ▒ output  ░ livre  (3 tons distintos como cache)
# Usa percentuais direto pra evitar divisao inteira zerando com tokens pequenos
ctx_combined_bar() {
  local in_pct="${1:-0}" out_pct="${2:-0}" w="${3:-6}"
  local in_fill=$(( (in_pct * w + 50) / 100 ))
  local out_fill=$(( (out_pct * w + 50) / 100 ))
  [[ $in_fill -gt $w ]] && in_fill=$w
  [[ $(( in_fill + out_fill )) -gt $w ]] && out_fill=$(( w - in_fill ))
  local free=$(( w - in_fill - out_fill ))
  [[ $free -lt 0 ]] && free=0
  local s="" i
  for (( i=0; i<in_fill;  i++ )); do s="${s}█"; done
  for (( i=0; i<out_fill; i++ )); do s="${s}▒"; done
  for (( i=0; i<free;     i++ )); do s="${s}░"; done
  local prefix=""
  (( in_pct >= 90 )) && prefix="▸▸" || { (( in_pct >= 75 )) && prefix="▸"; }
  echo "${prefix}${s}"
}

# Cache: ▓ hit  ▒ criado  ░ fresh — largura 4
cache_bar() {
  local hit_pct="${1:-0}" create_pct="${2:-0}" w="${3:-4}"
  local hit_fill=$(( (hit_pct * w + 50) / 100 ))
  local cre_fill=$(( (create_pct * w + 50) / 100 ))
  [[ $(( hit_fill + cre_fill )) -gt $w ]] && cre_fill=$(( w - hit_fill ))
  local fresh=$(( w - hit_fill - cre_fill ))
  local s="" i
  for (( i=0; i<hit_fill; i++ )); do s="${s}▓"; done
  for (( i=0; i<cre_fill; i++ )); do s="${s}▒"; done
  for (( i=0; i<fresh;    i++ )); do s="${s}░"; done
  echo "$s"
}

OUT_PCT=0
[[ "$CTX_SIZE" -gt 0 && "$OUT_TOKENS" -gt 0 ]] && OUT_PCT=$(( OUT_TOKENS * 100 / CTX_SIZE ))
CTX_BAR=$(ctx_combined_bar "$CTX_PCT" "$OUT_PCT" 6)

CACHE_CREATE_PCT=0
[[ $TOTAL_IN -gt 0 ]] && CACHE_CREATE_PCT=$(( CACHE_CREATE * 100 / TOTAL_IN ))
CACHE_BAR=$(cache_bar "$CACHE_HIT_PCT" "$CACHE_CREATE_PCT" 4)

# --- Secoes ---

# 1. Contexto: barra + in↑out/total  (ex: ████▓░░░ 55k↑8k/200k)
OUT_RAW=$(( OUT_TOKENS / 1000 ))
CTX_SIZE_RAW=$(( CTX_SIZE / 1000 ))
CTX_STR="${CTX_BAR} ${OUT_RAW}/${CTX_USED_K}/${CTX_SIZE_RAW}k"

# 2. Cache (so se tiver dados)
CACHE_STR=""
[[ $TOTAL_IN -gt 0 ]] && CACHE_STR=" 󰆼 ${CACHE_BAR}${CACHE_HIT_PCT}%"

# 3. Custo (so se > $0.01)
COST_STR=""
if [[ -n "$COST_USD" && "$COST_USD" != "0" && "$COST_USD" != "null" ]]; then
  _cost_cents=$(echo "$COST_USD" | awk '{printf "%d", $1 * 100}')
  [[ "${_cost_cents:-0}" -ge 1 ]] && COST_STR=" \$$(printf '%.2f' "$COST_USD")"
fi

# 4. Worktree
WT_STR=""
[[ -n "$WORKTREE_NAME" && "$WORKTREE_NAME" != "null" ]] && WT_STR=" wt:$WORKTREE_NAME"

# 5. Mount / workspace
MOUNT_STR=""
if [[ -n "${CLAUDIO_MOUNT:-}" ]]; then
  MOUNT_STR=" @ ${CLAUDIO_MOUNT}"
elif [[ -d "/workspace/mnt" ]] && [[ -n "$(ls -A /workspace/mnt 2>/dev/null)" ]]; then
  MOUNT_STR=" @ /workspace/mnt"
fi

# Icone: alerta se excedeu 200k, senão robot normal
[[ "$EXCEEDS" == "true" ]] && ICON="󰀦" || ICON="󱙺"

# Composicao final
RIGHT="${ICON} ${MODEL_SIZE} ${CTX_STR}${CACHE_STR}${COST_STR}${WT_STR}${MOUNT_STR}"

# Terminal title via OSC (stderr)
printf '\033]0;Claude: %s\007' "$TOPIC" >&2

echo "$RIGHT"
