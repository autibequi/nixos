# lib/state.sh — persiste a última config do wizard no diretório do projeto.
# Vira o default da próxima vez (no wizard e no modo --yes).

coruja_state_file() {
  echo "$(coruja_dir)/.coruja-state"
}

# Carrega o state salvo em STATE_* — só aceita valores válidos (à prova de arquivo corrompido).
state_load() {
  local f
  f="$(coruja_state_file)"
  [[ -f "$f" ]] || return 0

  local key val
  while IFS='=' read -r key val; do
    case "$key" in
      FRONT)    case "$val" in local | sandbox | qa | prod | devbox | skip) STATE_FRONT="$val" ;; esac ;;
      BO)       case "$val" in local | sandbox | qa | prod | skip) STATE_BO="$val" ;; esac ;;
      MONO)     case "$val" in auto | local | sandbox | sandbox-devbox | prod | skip) STATE_MONO="$val" ;; esac ;;
      MODE)     case "$val" in foreground | background) STATE_MODE="$val" ;; esac ;;
      VERTICAL) case "$val" in carreiras-juridicas | concursos | medicina | militares | oab | vestibulares) STATE_VERTICAL="$val" ;; esac ;;
      WORKER)   case "$val" in yes | no) STATE_WORKER="$val" ;; esac ;;
      PDFKIT)   case "$val" in yes | no) STATE_PDFKIT="$val" ;; esac ;;
      DEBUG)    case "$val" in 0 | 1) STATE_DEBUG="$val" ;; esac ;;
      AUTODOWN) case "$val" in off | 30m | 1h | 2h | 4h) STATE_AUTODOWN="$val" ;; esac ;;
      # Worktree por app: slug dinâmico (validado contra os worktrees reais na resolução,
      # não por allowlist). Só rejeita tokens com espaço/separador suspeito.
      MONO_WT)  [[ "$val" =~ ^[A-Za-z0-9._/-]+$ ]] && STATE_MONO_WT="$val" ;;
      BO_WT)    [[ "$val" =~ ^[A-Za-z0-9._/-]+$ ]] && STATE_BO_WT="$val" ;;
      FRONT_WT) [[ "$val" =~ ^[A-Za-z0-9._/-]+$ ]] && STATE_FRONT_WT="$val" ;;
    esac
  done < "$f"
  return 0
}

# Salva a config atual (lê FRONT_ENV / BO_SEL / MONO_SEL / RUN_MODE / VERTICAL_SEL).
state_save() {
  local f
  f="$(coruja_state_file)"
  {
    echo "# coruja — última config usada (gerado automaticamente; não commitar)"
    echo "FRONT=$FRONT_ENV"
    echo "BO=$BO_SEL"
    echo "MONO=$MONO_SEL"
    echo "MODE=$RUN_MODE"
    echo "VERTICAL=$VERTICAL_SEL"
    echo "WORKER=$WORKER_SEL"
    echo "PDFKIT=${PDFKIT_SEL:-no}"
    echo "DEBUG=${MONO_DEBUG:-0}"
    echo "AUTODOWN=${AUTO_DOWN:-1h}"
    echo "MONO_WT=${MONO_WT:-main}"
    echo "BO_WT=${BO_WT:-main}"
    echo "FRONT_WT=${FRONT_WT:-main}"
  } > "$f" 2>/dev/null || echo "aviso: não consegui salvar o state em $f" >&2
}

# Atualiza só as chaves de worktree, preservando o resto do state. O `coruja worktrees`
# não roda o wizard, então não tem as demais globais (FRONT_ENV/MONO_SEL/…) pra um
# state_save completo — sem isto, salvar zeraria a última config de ambiente.
state_save_worktrees() {
  local mono="$1" bo="$2" front="$3"
  local f tmp
  f="$(coruja_state_file)"
  tmp="$(mktemp)" || { echo "aviso: não consegui salvar os worktrees" >&2; return 0; }

  [[ -f "$f" ]] && grep -vE '^(MONO_WT|BO_WT|FRONT_WT)=' "$f" > "$tmp"
  {
    echo "MONO_WT=$mono"
    echo "BO_WT=$bo"
    echo "FRONT_WT=$front"
  } >> "$tmp"

  mv "$tmp" "$f" 2>/dev/null || echo "aviso: não consegui salvar os worktrees em $f" >&2
}
