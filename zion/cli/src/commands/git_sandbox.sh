# git append — merge da branch atual em <BRANCH> (recriada limpa do remote), push, volta.
#
# Fluxo:
#   1. detecta branch atual
#   2. git fetch origin
#   3. inspeciona o que existe em origin/<target> (avisa se tiver commits a perder)
#   4. pede confirmação y/n antes de apagar
#   5. deleta target local + recria de origin/<target>
#   6. git merge <current> --no-edit
#   7. git push origin <target>  (a menos que --no-push)
#   8. git checkout <current>

set -e

target="${args[branch]}"
no_push="${args[--no-push]:-}"
yes="${args[--yes]:-}"

# ── helpers visuais ───────────────────────────────────────────────────────────
_ok()   { printf "  \033[32m✓\033[0m  %s\n" "$*"; }
_run()  { printf "  \033[2m→ %s\033[0m\n" "$*"; }
_err()  { printf "  \033[31m✗\033[0m  %s\n" "$*" >&2; }
_warn() { printf "  \033[33m⚠\033[0m  %s\n" "$*"; }
_info() { printf "  \033[2m%s\033[0m\n" "$*"; }

# ── detecta branch atual ──────────────────────────────────────────────────────
current="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
if [[ -z "$current" || "$current" == "HEAD" ]]; then
  _err "nao foi possivel detectar a branch atual (HEAD detached?)."
  exit 1
fi

if [[ "$current" == "$target" ]]; then
  _err "voce ja esta na branch '$target'. Mude para a branch que quer mergear."
  exit 1
fi

# ── header ────────────────────────────────────────────────────────────────────
printf "\n\033[1m  zion git append\033[0m\n"
printf "  \033[2m%s  →  %s\033[0m\n\n" "$current" "$target"

# ── 1. fetch ──────────────────────────────────────────────────────────────────
_run "git fetch origin"
git fetch origin --quiet
_ok "fetch"

# ── 2. verificar se origin/target existe ─────────────────────────────────────
if ! git ls-remote --exit-code --heads origin "$target" &>/dev/null; then
  _err "origin/$target nao encontrada. Verifique o nome da branch destino."
  exit 1
fi

# ── 3. inspecionar divergencia do target ─────────────────────────────────────
# commits que existem em origin/target mas NAO em origin/target^{/merge-base com current}
# simplificado: mostrar commits em origin/target que nao estao em current
ahead_count="$(git rev-list --count "refs/remotes/origin/$target" --not "refs/remotes/origin/$current" 2>/dev/null || echo "?")"

if [[ "$ahead_count" == "0" ]]; then
  _info "$target esta sincronizada com $current (nada sera perdido)"
elif [[ "$ahead_count" == "?" ]]; then
  _warn "nao foi possivel calcular divergencia de $target"
else
  _warn "origin/$target tem $ahead_count commit(s) que NAO estao em $current:"
  git log --oneline --no-walk=unsorted \
    "refs/remotes/origin/$target" --not "refs/remotes/origin/$current" \
    2>/dev/null | head -8 | sed 's/^/       /'
  printf "\n"
  _warn "esses commits serao APAGADOS ao recriar $target do remote."
fi

printf "\n"

# ── 4. confirmação ────────────────────────────────────────────────────────────
if [[ -z "$yes" ]]; then
  printf "  Recriar \033[1m%s\033[0m do remote e mergear \033[1m%s\033[0m? " "$target" "$current"
  printf "\033[2m[Enter/y = sim  |  n/Esc = cancelar]\033[0m "
  read -r -n1 answer </dev/tty
  printf "\n\n"

  case "${answer,,}" in
    ""|y) ;;  # Enter ou y: continua
    *)
      printf "  Cancelado.\n\n"
      exit 0
      ;;
  esac
fi

# ── 5. recriar target local limpo ────────────────────────────────────────────
_run "recriando $target do origin/$target (limpo)"
git checkout "$current" --quiet 2>/dev/null || true
git branch -D "$target" --quiet 2>/dev/null || true
git checkout -b "$target" "origin/$target" --no-track --quiet
_ok "$target recriado"

# ── 6. merge ──────────────────────────────────────────────────────────────────
_run "git merge $current --no-edit"
if ! merge_out="$(git merge "$current" --no-edit 2>&1)"; then
  printf "%s\n" "$merge_out" | sed 's/^/     /'
  _err "merge falhou. Resolva os conflitos manualmente."
  git merge --abort 2>/dev/null || true
  git checkout "$current" --quiet 2>/dev/null || true
  exit 1
fi
printf "%s\n" "$merge_out" | grep -v "^$" | sed 's/^/     /' || true
_ok "merge ok"

# ── 7. push ───────────────────────────────────────────────────────────────────
if [[ -z "$no_push" ]]; then
  _run "git push origin $target"
  git push origin "$target" 2>&1 | sed 's/^/     /'
  _ok "push ok"
fi

# ── 8. volta para branch original ─────────────────────────────────────────────
git checkout "$current" --quiet
_ok "de volta em $current"

printf "\n  \033[32m\033[1mFeito!\033[0m  %s → %s\n\n" "$current" "$target"
