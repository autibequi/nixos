#!/usr/bin/env bash
# kanban-sync.sh — Operações atômicas no vault/kanban.md
# Todas as funções usam flock para concorrência segura entre workers
set -euo pipefail

KANBAN="${KANBAN_FILE:-/workspace/vault/kanban.md}"
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
# Retorna: START_LINE END_LINE (globais)
_find_column() {
  local column="$1"
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
  done < "$KANBAN"

  if [ "$found" = "1" ]; then
    COLUMN_END=$line_num  # EOF
    return 0
  fi
  return 1
}

# Extrai nome da task de um card line (ex: "- [ ] **doctor** ..." → "doctor")
_card_name() {
  local line="$1"
  local after="${line#*\*\*}"
  echo "${after%%\*\**}"
}

# Adiciona [worker] tag após **task** no card
_add_worker_tag() {
  local line="$1" task="$2" worker="$3"
  local before="${line%%\*\*${task}\*\**}"
  local after="${line#*\*\*${task}\*\*}"
  echo "${before}**${task}** [${worker}]${after}"
}

# Extrai número de #retry-N de uma linha
_get_retry_num() {
  local line="$1"
  if [[ "$line" == *"#retry-"* ]]; then
    local after="${line#*#retry-}"
    local num="${after%% *}"
    num="${num%%[!0-9]*}"
    echo "${num:-0}"
  else
    echo "0"
  fi
}

# Remove #retry-N e #dead tags de um card
_clean_retry_tags() {
  local line="$1"
  # Remove #retry-N
  while [[ "$line" == *"#retry-"* ]]; do
    local before="${line%% #retry-*}"
    local after="${line#*#retry-}"
    after="${after#*[0-9]}"
    line="${before}${after}"
  done
  # Remove #dead
  line="${line// #dead/}"
  # Clean double spaces
  while [[ "$line" == *"  "* ]]; do
    line="${line//  / }"
  done
  echo "$line"
}

# ── Funções públicas ─────────────────────────────────────────────

# Lista cards de uma coluna (linhas que começam com "- [")
kanban_read_column() {
  local column="$1"
  _find_column "$column" || { echo "[kanban-sync] Coluna '$column' não encontrada" >&2; return 1; }

  local line_num=0
  while IFS= read -r line; do
    if [ "$line_num" -gt "$COLUMN_START" ] && [ "$line_num" -lt "$COLUMN_END" ]; then
      if [[ "$line" =~ ^-\ \[ ]]; then
        echo "$line"
      fi
    fi
    line_num=$((line_num + 1))
  done < "$KANBAN"
}

# Move card do Backlog → Em Andamento, adicionando [worker-N]
# Uso: kanban_claim_card "task-name" "worker-1"
kanban_claim_card() {
  local task="$1" worker="$2"
  _kanban_atomic _do_claim_card "$task" "$worker"
}

_do_claim_card() {
  local task="$1" worker="$2"
  local tmp
  tmp=$(mktemp)
  local found=0
  local card_line=""
  local in_backlog=0
  local in_andamento=0
  local inserted=0

  while IFS= read -r line; do
    if [ "$line" = "## Backlog" ]; then
      in_backlog=1
      echo "$line" >> "$tmp"
      continue
    fi
    if [[ "$line" =~ ^##\  ]] && [ "$in_backlog" = "1" ]; then
      in_backlog=0
    fi

    # Encontrou o card no Backlog — remove
    if [ "$in_backlog" = "1" ] && [[ "$line" =~ ^-\ \[ ]] && [[ "$line" == *"**${task}**"* ]]; then
      card_line="$line"
      found=1
      continue  # não escreve essa linha (remove do Backlog)
    fi

    # Ao encontrar "## Em Andamento", marca pra inserir depois
    if [ "$line" = "## Em Andamento" ]; then
      in_andamento=1
      echo "$line" >> "$tmp"
      continue
    fi

    # Inserir card no início de Em Andamento (após header + linha vazia)
    if [ "$in_andamento" = "1" ] && [ "$inserted" = "0" ] && [ "$found" = "1" ]; then
      if [ -z "$line" ] || [[ "$line" =~ ^-\ \[ ]] || [[ "$line" =~ ^##\  ]]; then
        # Adiciona marcação do worker no card
        local new_card
        new_card=$(_add_worker_tag "$card_line" "$task" "$worker")
        [ -z "$line" ] && echo "" >> "$tmp"
        echo "$new_card" >> "$tmp"
        inserted=1
        if [[ "$line" =~ ^##\  ]] || [[ "$line" =~ ^-\ \[ ]]; then
          echo "$line" >> "$tmp"
        fi
        in_andamento=0
        continue
      fi
    fi

    echo "$line" >> "$tmp"
  done < "$KANBAN"

  # Se não inseriu ainda (Em Andamento era a última coluna ou vazia)
  if [ "$found" = "1" ] && [ "$inserted" = "0" ]; then
    local new_card
    new_card=$(_add_worker_tag "$card_line" "$task" "$worker")
    echo "$new_card" >> "$tmp"
  fi

  if [ "$found" = "1" ]; then
    mv "$tmp" "$KANBAN"
    echo "[kanban-sync] '$task' claimed por $worker (Backlog → Em Andamento)"
  else
    rm -f "$tmp"
    echo "[kanban-sync] '$task' não encontrado no Backlog" >&2
    return 1
  fi
}

# Move card de Em Andamento → Concluido com link pro report
# Uso: kanban_complete_card "task-name" "vault/_agent/reports/2026-03-13-foo.md"
kanban_complete_card() {
  local task="$1" report_link="${2:-}"
  _kanban_atomic _do_complete_card "$task" "$report_link"
}

_do_complete_card() {
  local task="$1" report_link="$2"
  local tmp
  tmp=$(mktemp)
  local found=0
  local card_line=""
  local in_andamento=0
  local in_concluido=0
  local inserted=0

  while IFS= read -r line; do
    if [ "$line" = "## Em Andamento" ]; then
      in_andamento=1
      echo "$line" >> "$tmp"
      continue
    fi
    if [[ "$line" =~ ^##\  ]] && [ "$in_andamento" = "1" ]; then
      in_andamento=0
    fi

    # Remove card de Em Andamento
    if [ "$in_andamento" = "1" ] && [[ "$line" =~ ^-\ \[ ]] && [[ "$line" == *"**${task}**"* ]]; then
      card_line="$line"
      found=1
      continue
    fi

    # Inserir no Concluido
    if [ "$line" = "## Concluido" ]; then
      in_concluido=1
      echo "$line" >> "$tmp"
      continue
    fi

    if [ "$in_concluido" = "1" ] && [ "$inserted" = "0" ] && [ "$found" = "1" ]; then
      if [ -z "$line" ] || [[ "$line" =~ ^-\ \[ ]] || [[ "$line" =~ ^##\  ]]; then
        # Formatar card como concluído
        local done_card="- [x] **${task}** #done $(date +%Y-%m-%d)"
        if [ -n "$report_link" ]; then
          done_card="$done_card — [report](${report_link})"
        fi
        [ -z "$line" ] && echo "" >> "$tmp"
        echo "$done_card" >> "$tmp"
        inserted=1
        in_concluido=0
        if [[ "$line" =~ ^##\  ]] || [[ "$line" =~ ^-\ \[ ]]; then
          echo "$line" >> "$tmp"
        fi
        continue
      fi
    fi

    echo "$line" >> "$tmp"
  done < "$KANBAN"

  if [ "$found" = "1" ] && [ "$inserted" = "0" ]; then
    echo "- [x] **${task}** #done $(date +%Y-%m-%d)${report_link:+ — [report](${report_link})}" >> "$tmp"
  fi

  if [ "$found" = "1" ]; then
    mv "$tmp" "$KANBAN"
    echo "[kanban-sync] '$task' concluído (Em Andamento → Concluido)"
  else
    rm -f "$tmp"
    echo "[kanban-sync] '$task' não encontrado em Em Andamento" >&2
    return 1
  fi
}

# Move card de Em Andamento → Falhou com motivo e tag retry
# Uso: kanban_fail_card "task-name" "timeout após 300s"
kanban_fail_card() {
  local task="$1" reason="${2:-unknown}"
  _kanban_atomic _do_fail_card "$task" "$reason"
}

_do_fail_card() {
  local task="$1" reason="$2"
  local tmp
  tmp=$(mktemp)
  local found=0
  local card_line=""
  local in_andamento=0
  local in_falhou=0
  local inserted=0

  # Contar retries existentes na coluna Falhou
  local retry_count=0
  while IFS= read -r line; do
    if [[ "$line" == *"**${task}**"* ]] && [[ "$line" == *"#retry-"* ]]; then
      local n
      n=$(_get_retry_num "$line")
      [ -n "$n" ] && [ "$n" -gt "$retry_count" ] && retry_count=$n
    fi
  done < "$KANBAN"
  retry_count=$((retry_count + 1))

  while IFS= read -r line; do
    if [ "$line" = "## Em Andamento" ]; then
      in_andamento=1
      echo "$line" >> "$tmp"
      continue
    fi
    if [[ "$line" =~ ^##\  ]] && [ "$in_andamento" = "1" ]; then
      in_andamento=0
    fi

    # Remove de Em Andamento
    if [ "$in_andamento" = "1" ] && [[ "$line" =~ ^-\ \[ ]] && [[ "$line" == *"**${task}**"* ]]; then
      card_line="$line"
      found=1
      continue
    fi

    # Inserir em Falhou
    if [ "$line" = "## Falhou" ]; then
      in_falhou=1
      echo "$line" >> "$tmp"
      continue
    fi

    if [ "$in_falhou" = "1" ] && [ "$inserted" = "0" ] && [ "$found" = "1" ]; then
      local dead_tag=""
      [ "$retry_count" -ge 3 ] && dead_tag=" #dead"
      local fail_card="- [ ] **${task}** #retry-${retry_count}${dead_tag} $(date +%Y-%m-%d) — ${reason}"
      if [ -z "$line" ] || [[ "$line" =~ ^-\ \[ ]] || [[ "$line" =~ ^##\  ]]; then
        [ -z "$line" ] && echo "" >> "$tmp"
        echo "$fail_card" >> "$tmp"
        inserted=1
        in_falhou=0
        if [[ "$line" =~ ^##\  ]] || [[ "$line" =~ ^-\ \[ ]]; then
          echo "$line" >> "$tmp"
        fi
        continue
      fi
    fi

    echo "$line" >> "$tmp"
  done < "$KANBAN"

  if [ "$found" = "1" ] && [ "$inserted" = "0" ]; then
    local dead_tag=""
    [ "$retry_count" -ge 3 ] && dead_tag=" #dead"
    echo "- [ ] **${task}** #retry-${retry_count}${dead_tag} $(date +%Y-%m-%d) — ${reason}" >> "$tmp"
  fi

  if [ "$found" = "1" ]; then
    mv "$tmp" "$KANBAN"
    echo "[kanban-sync] '$task' falhou #retry-${retry_count} (Em Andamento → Falhou)"
  else
    rm -f "$tmp"
    echo "[kanban-sync] '$task' não encontrado em Em Andamento" >&2
    return 1
  fi
}

# Adiciona card numa coluna específica
# Uso: kanban_add_card "Backlog" "- [ ] **minha-task** #pending 2026-03-13 \`haiku\` — descrição"
kanban_add_card() {
  local column="$1" card="$2"
  _kanban_atomic _do_add_card "$column" "$card"
}

_do_add_card() {
  local column="$1" card="$2"
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

    # Inserir após a primeira linha vazia da coluna
    if [ "$in_column" = "1" ] && [ "$inserted" = "0" ]; then
      if [ -z "$line" ]; then
        echo "$card" >> "$tmp"
        inserted=1
        in_column=0
      fi
    fi
  done < "$KANBAN"

  if [ "$inserted" = "1" ]; then
    mv "$tmp" "$KANBAN"
    echo "[kanban-sync] Card adicionado em '$column'"
  else
    rm -f "$tmp"
    echo "[kanban-sync] Coluna '$column' não encontrada ou sem linha vazia" >&2
    return 1
  fi
}

# Copia card de Recorrentes → Em Andamento (original fica)
# Uso: kanban_claim_recurring "doctor" "worker-1"
kanban_claim_recurring() {
  local task="$1" worker="$2"
  _kanban_atomic _do_claim_recurring "$task" "$worker"
}

_do_claim_recurring() {
  local task="$1" worker="$2"

  # Verificar se já está em andamento
  local already=0
  while IFS= read -r line; do
    if [[ "$line" == *"**${task}**"* ]] && [[ "$line" == *"[worker-"* ]]; then
      already=1
      break
    fi
  done < <(kanban_read_column "Em Andamento" 2>/dev/null || true)

  if [ "$already" = "1" ]; then
    echo "[kanban-sync] '$task' já em andamento por outro worker" >&2
    return 1
  fi

  # Encontrar card nos Recorrentes
  local card_line=""
  while IFS= read -r line; do
    if [[ "$line" == *"**${task}**"* ]]; then
      card_line="$line"
      break
    fi
  done < <(kanban_read_column "Recorrentes" 2>/dev/null || true)

  if [ -z "$card_line" ]; then
    echo "[kanban-sync] '$task' não encontrado em Recorrentes" >&2
    return 1
  fi

  # Adicionar cópia em Em Andamento com worker tag
  local new_card
  new_card=$(_add_worker_tag "$card_line" "$task" "$worker")
  _do_add_card "Em Andamento" "$new_card"
}

# Remove cópia de recurring de Em Andamento
# Uso: kanban_unclaim_recurring "doctor"
kanban_unclaim_recurring() {
  local task="$1"
  _kanban_atomic _do_unclaim_recurring "$task"
}

_do_unclaim_recurring() {
  local task="$1"
  local tmp
  tmp=$(mktemp)
  local found=0
  local in_andamento=0

  while IFS= read -r line; do
    if [ "$line" = "## Em Andamento" ]; then
      in_andamento=1
      echo "$line" >> "$tmp"
      continue
    fi
    if [[ "$line" =~ ^##\  ]] && [ "$in_andamento" = "1" ]; then
      in_andamento=0
    fi

    # Remove card de Em Andamento
    if [ "$in_andamento" = "1" ] && [[ "$line" =~ ^-\ \[ ]] && [[ "$line" == *"**${task}**"* ]]; then
      found=1
      continue
    fi

    echo "$line" >> "$tmp"
  done < "$KANBAN"

  if [ "$found" = "1" ]; then
    mv "$tmp" "$KANBAN"
    echo "[kanban-sync] '$task' removido de Em Andamento (recurring unclaim)"
  else
    rm -f "$tmp"
    echo "[kanban-sync] '$task' não encontrado em Em Andamento" >&2
    return 1
  fi
}

# Retorna cards de uma coluna como nomes (sem formatação)
kanban_list_names() {
  local column="$1"
  kanban_read_column "$column" 2>/dev/null | while IFS= read -r line; do
    _card_name "$line"
  done
}

# Conta cards por coluna (para dashboard/statusline)
kanban_count() {
  local column="$1"
  kanban_read_column "$column" 2>/dev/null | wc -l
}

# Move card de Falhou → Backlog (para retry)
# Uso: kanban_retry_card "task-name"
kanban_retry_card() {
  local task="$1"
  _kanban_atomic _do_retry_card "$task"
}

_do_retry_card() {
  local task="$1"
  local tmp
  tmp=$(mktemp)
  local found=0
  local card_line=""
  local in_falhou=0
  local in_backlog=0
  local inserted=0

  while IFS= read -r line; do
    if [ "$line" = "## Falhou" ]; then
      in_falhou=1
      echo "$line" >> "$tmp"
      continue
    fi
    if [[ "$line" =~ ^##\  ]] && [ "$in_falhou" = "1" ]; then
      in_falhou=0
    fi

    # Remove de Falhou (pega o mais recente)
    if [ "$in_falhou" = "1" ] && [[ "$line" =~ ^-\ \[ ]] && [[ "$line" == *"**${task}**"* ]]; then
      if [ "$found" = "0" ]; then
        card_line="$line"
        found=1
        continue
      fi
    fi

    # Inserir no Backlog
    if [ "$line" = "## Backlog" ]; then
      in_backlog=1
      echo "$line" >> "$tmp"
      continue
    fi

    if [ "$in_backlog" = "1" ] && [ "$inserted" = "0" ] && [ "$found" = "1" ]; then
      if [ -z "$line" ]; then
        echo "" >> "$tmp"
        # Limpar retry tags do card
        local clean_card
        clean_card=$(_clean_retry_tags "$card_line")
        echo "$clean_card" >> "$tmp"
        inserted=1
        in_backlog=0
        continue
      fi
    fi

    echo "$line" >> "$tmp"
  done < "$KANBAN"

  if [ "$found" = "1" ]; then
    mv "$tmp" "$KANBAN"
    echo "[kanban-sync] '$task' retornado (Falhou → Backlog)"
  else
    rm -f "$tmp"
    echo "[kanban-sync] '$task' não encontrado em Falhou" >&2
    return 1
  fi
}
