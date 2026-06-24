# lib/wizard.sh — seleção interativa.
# Preferência de UI: gum > fzf > fallback texto. (o host pode ter só um dos dois)

_has() { command -v "$1" >/dev/null 2>&1; }

# pick_env <label> <default> <opt>...
# Escolha única. Escreve a opção em stdout (prompts vão pra stderr p/ não poluir a captura).
pick_env() {
  local label="$1"; shift
  local default="$1"; shift
  local opts=("$@")

  if _has gum; then
    gum choose --header "$label" --selected "$default" "${opts[@]}"
    return
  fi

  if _has fzf; then
    # default no topo → cursor inicial cai nele (reflete o state/última config).
    local reordered=("$default") o
    for o in "${opts[@]}"; do
      [[ "$o" != "$default" ]] && reordered+=("$o")
    done
    printf '%s\n' "${reordered[@]}" | fzf --height 10 --layout reverse \
      --header "$label  (↑↓ move · ↵ escolhe · topo = $default)"
    return
  fi

  {
    echo "$label"
    local i=1 o
    for o in "${opts[@]}"; do
      printf "  %d) %s\n" "$i" "$o"
      i=$((i + 1))
    done
    printf "  escolha [1-%d, enter = %s]: " "${#opts[@]}" "$default"
  } >&2

  local choice
  read -r choice
  if [[ -z "$choice" ]]; then
    echo "$default"
    return
  fi
  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#opts[@]} )); then
    echo "${opts[$((choice - 1))]}"
  else
    echo "$default"
  fi
}

# pick_multi <label> <opt>...
# Escolha múltipla. Imprime os escolhidos (um por linha). Default = todos marcados.
pick_multi() {
  local label="$1"; shift
  local opts=("$@")

  if _has gum; then
    local sel
    sel="$(IFS=,; echo "${opts[*]}")"
    gum choose --no-limit --header "$label  (espaço marca · ↵ confirma)" --selected "$sel" "${opts[@]}"
    return
  fi

  if _has fzf; then
    # start:select-all → todos pré-marcados; TAB desmarca o que não quer.
    printf '%s\n' "${opts[@]}" | fzf --multi --bind 'start:select-all' \
      --height 12 --layout reverse \
      --header "$label  (TAB marca/desmarca · ↵ confirma · todos pré-marcados)"
    return
  fi

  echo "$label" >&2
  local o ans
  for o in "${opts[@]}"; do
    printf "  incluir %s? [Y/n]: " "$o" >&2
    read -r ans
    case "$ans" in
      [nN] | [nN][oO]) ;;
      *) echo "$o" ;;
    esac
  done
}

confirm() {
  local prompt="${1:-Confirma?}"
  local ans
  printf "%s [Y/n] " "$prompt" >&2
  read -r ans
  case "$ans" in
    [nN] | [nN][oO] | [nN][aA][oO]) return 1 ;;
    *) return 0 ;;
  esac
}
