#!/usr/bin/env bash
# kanban-sync.sh — Operações atômicas no vault/kanban.md
# Todas as funções usam flock para concorrência segura entre workers
set -euo pipefail

KANBAN="${KANBAN_FILE:-/workspace/vault/kanban.md}"
SCHEDULED="${SCHEDULED_FILE:-/workspace/vault/scheduled.md}"
LOCKFILE="${KANBAN_LOCKFILE:-/workspace/.ephemeral/.kanban.lock}"

mkdir -p "$(dirname "$LOCKFILE")"

# ── Helpers internos ─────────────────────────────────────────────

# Executa operação atômica no kanban (read-modify-write com flock)
_kanban_atomic() {
  local callback="$1"
  shift
  (
    flock -w 5 200 || { echo "[kanban-sync] ERRO: não conseguiu lock em 5s" >&2; return 1; }
    "$callback" "$@"
  ) 200>"$LOCKFILE"
}

# Encontra linhas de início e fim de uma coluna (0-indexed)
# Usage: _find_column "ColName" [file]  (default: $KANBAN)
_find_column() {
  local column="$1"
  local file="${2:-$KANBAN}"
  local header="## $column"
  COLUMN_START=-1
  COLUMN_END=-1

  local line_num=0
  local found=0
  while IFS= read -r line; do
    if [ "$found" = "1" ] && [[ "$line" =~ ^##\  ]]; then
      COLUMN_END=$line_num
      return 0
    fi
    if [ "$line" = "$header" ]; then
      COLUMN_START=$line_num
      found=1
    fi
    line_num=$((line_num + 1))
  done < "$file"

  if [ "$found" = "1" ]; then
    COLUMN_END=$line_num  # EOF
    return 0
  fi
  return 1
}

# Extrai nome da task de um card line
_card_name() {
  local line="$1"
  local after="${line#*\*\*}"
  echo "${after%%\*\**}"
}

# Adiciona [worker] tag após **task**
_add_worker_tag() {
  local line="$1" task="$2" worker="$3"
  local before="${line%%\*\*${task}\*\**}"
  local after="${line#*\*\*${task}\*\*}"
  echo "${before}**${task}** [${worker}]${after}"
}

# ── Operação genérica: mover card entre colunas ──────────────────

# _do_move_card source_col dest_col task transform_fn [extra_args...]
# transform_fn recebe a card line e extra_args, retorna a new card line
_do_move_card() {
  local source_col="$1" dest_col="$2" task="$3" transform_fn="$4"
  shift 4
  local extra_args=("$@")

  local tmp
  tmp=$(mktemp)
  local found=0
  local card_line=""
  local in_source=0
  local in_dest=0
  local inserted=0

  while IFS= read -r line; do
    if [ "$line" = "## $source_col" ]; then
      in_source=1
      echo "$line" >> "$tmp"
      continue
    fi
    if [[ "$line" =~ ^##\  ]] && [ "$in_source" = "1" ]; then
      in_source=0
    fi

    # Remove card from source
    if [ "$in_source" = "1" ] && [[ "$line" =~ ^-\ \[ ]] && [[ "$line" == *"**${task}**"* ]]; then
      card_line="$line"
      found=1
      continue
    fi

    # Insert into dest
    if [ "$line" = "## $dest_col" ]; then
      in_dest=1
      echo "$line" >> "$tmp"
      continue
    fi

    if [ "$in_dest" = "1" ] && [ "$inserted" = "0" ] && [ "$found" = "1" ]; then
      if [ -z "$line" ] || [[ "$line" =~ ^-\ \[ ]] || [[ "$line" =~ ^##\  ]]; then
        local new_card
        new_card=$("$transform_fn" "$card_line" "$task" "${extra_args[@]}")
        [ -z "$line" ] && echo "" >> "$tmp"
        echo "$new_card" >> "$tmp"
        inserted=1
        in_dest=0
        if [[ "$line" =~ ^##\  ]] || [[ "$line" =~ ^-\ \[ ]]; then
          echo "$line" >> "$tmp"
        fi
        continue
      fi
    fi

    echo "$line" >> "$tmp"
  done < "$KANBAN"

  # If dest was last column or empty
  if [ "$found" = "1" ] && [ "$inserted" = "0" ]; then
    local new_card
    new_card=$("$transform_fn" "$card_line" "$task" "${extra_args[@]}")
    echo "$new_card" >> "$tmp"
  fi

  if [ "$found" = "1" ]; then
    mv "$tmp" "$KANBAN"
    echo "[kanban-sync] '$task' ($source_col → $dest_col)"
  else
    rm -f "$tmp"
    echo "[kanban-sync] '$task' não encontrado em $source_col" >&2
    return 1
  fi
}

# ── Transform functions ──────────────────────────────────────────

_transform_claim() {
  local card="$1" task="$2" worker="$3"
  _add_worker_tag "$card" "$task" "$worker"
}

_transform_complete() {
  local _card="$1" task="$2" report="$3"
  local done_card="- [x] **${task}** #done $(date +%Y-%m-%d)"
  [ -n "$report" ] && done_card="$done_card — [report](${report})"
  echo "$done_card"
}

_transform_fail() {
  local _card="$1" task="$2" reason="$3"
  echo "- [ ] **${task}** #failed $(date +%Y-%m-%d) — ${reason}"
}

# ── Funções públicas ─────────────────────────────────────────────

# Lista cards de uma coluna
# Usage: kanban_read_column "ColName" [file]  (default: $KANBAN)
kanban_read_column() {
  local column="$1"
  local file="${2:-$KANBAN}"
  _find_column "$column" "$file" || { echo "[kanban-sync] Coluna '$column' não encontrada em $file" >&2; return 1; }

  local line_num=0
  while IFS= read -r line; do
    if [ "$line_num" -gt "$COLUMN_START" ] && [ "$line_num" -lt "$COLUMN_END" ]; then
      if [[ "$line" =~ ^-\ \[ ]]; then
        echo "$line"
      fi
    fi
    line_num=$((line_num + 1))
  done < "$file"
}

# Move card do Backlog → Em Andamento com [worker-N]
kanban_claim_card() {
  local task="$1" worker="$2"
  _kanban_atomic _do_move_card "Backlog" "Em Andamento" "$task" "_transform_claim" "$worker"
}

# Move card de Em Andamento → Concluido
kanban_complete_card() {
  local task="$1" report_link="${2:-}"
  _kanban_atomic _do_move_card "Em Andamento" "Concluido" "$task" "_transform_complete" "$report_link"
}

# Move card de Em Andamento → Falhou
kanban_fail_card() {
  local task="$1" reason="${2:-unknown}"
  _kanban_atomic _do_move_card "Em Andamento" "Falhou" "$task" "_transform_fail" "$reason"
}

# Adiciona card numa coluna específica
kanban_add_card() {
  local column="$1" card="$2"
  _kanban_atomic _do_add_card "$column" "$card"
}

# _do_add_card_in column card file — adiciona card em coluna de qualquer arquivo
_do_add_card_in() {
  local column="$1" card="$2" file="$3"
  local tmp
  tmp=$(mktemp)
  local in_column=0
  local inserted=0

  while IFS= read -r line; do
    echo "$line" >> "$tmp"

    if [ "$line" = "## $column" ]; then
      in_column=1
      continue
    fi

    if [ "$in_column" = "1" ] && [ "$inserted" = "0" ]; then
      if [ -z "$line" ]; then
        echo "$card" >> "$tmp"
        inserted=1
        in_column=0
      fi
    fi
  done < "$file"

  if [ "$inserted" = "1" ]; then
    mv "$tmp" "$file"
    echo "[kanban-sync] Card adicionado em '$column' ($file)"
  else
    rm -f "$tmp"
    echo "[kanban-sync] Coluna '$column' não encontrada ou sem linha vazia em $file" >&2
    return 1
  fi
}

_do_add_card() {
  local column="$1" card="$2"
  _do_add_card_in "$column" "$card" "$KANBAN"
}

# Copia card de Recorrentes → Em Execução no scheduled.md (original fica)
kanban_claim_recurring() {
  local task="$1" worker="$2"
  _kanban_atomic _do_claim_recurring "$task" "$worker"
}

_do_claim_recurring() {
  local task="$1" worker="$2"

  # Verificar se já está em execução no scheduled
  local already=0
  while IFS= read -r line; do
    if [[ "$line" == *"**${task}**"* ]] && [[ "$line" == *"[worker-"* ]]; then
      already=1
      break
    fi
  done < <(kanban_read_column "Em Execução" "$SCHEDULED" 2>/dev/null || true)

  if [ "$already" = "1" ]; then
    echo "[kanban-sync] '$task' já em execução por outro worker" >&2
    return 1
  fi

  # Encontrar card nos Recorrentes
  local card_line=""
  while IFS= read -r line; do
    if [[ "$line" == *"**${task}**"* ]]; then
      card_line="$line"
      break
    fi
  done < <(kanban_read_column "Recorrentes" "$SCHEDULED" 2>/dev/null || true)

  if [ -z "$card_line" ]; then
    echo "[kanban-sync] '$task' não encontrado em Recorrentes" >&2
    return 1
  fi

  local new_card
  new_card=$(_add_worker_tag "$card_line" "$task" "$worker")
  _do_add_card_in "Em Execução" "$new_card" "$SCHEDULED"
}

# Remove cópia de recurring de Em Execução no scheduled.md
kanban_unclaim_recurring() {
  local task="$1"
  _kanban_atomic _do_unclaim_recurring "$task"
}

_do_unclaim_recurring() {
  local task="$1"
  local tmp
  tmp=$(mktemp)
  local found=0
  local in_col=0

  while IFS= read -r line; do
    if [ "$line" = "## Em Execução" ]; then
      in_col=1
      echo "$line" >> "$tmp"
      continue
    fi
    if [[ "$line" =~ ^##\  ]] && [ "$in_col" = "1" ]; then
      in_col=0
    fi

    if [ "$in_col" = "1" ] && [[ "$line" =~ ^-\ \[ ]] && [[ "$line" == *"**${task}**"* ]]; then
      found=1
      continue
    fi

    echo "$line" >> "$tmp"
  done < "$SCHEDULED"

  if [ "$found" = "1" ]; then
    mv "$tmp" "$SCHEDULED"
    echo "[kanban-sync] '$task' removido de Em Execução (recurring unclaim)"
  else
    rm -f "$tmp"
    echo "[kanban-sync] '$task' não encontrado em Em Execução" >&2
    return 1
  fi
}

# Retorna cards de uma coluna como nomes
# Usage: kanban_list_names "ColName" [file]  (default: $KANBAN)
kanban_list_names() {
  local column="$1"
  local file="${2:-$KANBAN}"
  kanban_read_column "$column" "$file" 2>/dev/null | while IFS= read -r line; do
    _card_name "$line"
  done
}

# Conta cards por coluna
# Usage: kanban_count "ColName" [file]  (default: $KANBAN)
kanban_count() {
  local column="$1"
  local file="${2:-$KANBAN}"
  kanban_read_column "$column" "$file" 2>/dev/null | wc -l
}
