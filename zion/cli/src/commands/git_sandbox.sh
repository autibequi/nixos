# git sandbox — recriar sandbox limpa do remote, mergear branch atual, push, voltar.
#
# Fluxo:
#   1. salva branch atual
#   2. git fetch origin
#   3. deleta target local (se existir)
#   4. checkout -b target origin/target  (limpo do remote)
#   5. git merge <branch> --no-edit
#   6. git push origin <target>          (a menos que --no-push)
#   7. git checkout <branch original>

set -e

target="${args[--target]:-sandbox}"
no_push="${args[--no-push]:-}"

# Detecta branch atual
current="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
if [[ -z "$current" || "$current" == "HEAD" ]]; then
  echo "Erro: nao foi possivel detectar a branch atual (HEAD detached?)."
  exit 1
fi

# Branch a mergear (arg opcional, default = atual)
branch="${args[branch]:-$current}"

if [[ "$branch" == "$target" ]]; then
  echo "Erro: branch '$branch' e o proprio destino '$target'. Mude para a branch que quer mergear."
  exit 1
fi

# ── helpers visuais ───────────────────────────────────────────────────────────

_ok()  { printf "  \033[32m✓\033[0m  %s\n" "$*"; }
_run() { printf "  \033[2m→ %s\033[0m\n" "$*"; }
_err() { printf "  \033[31m✗\033[0m  %s\n" "$*" >&2; }

printf "\n\033[1m  zion git sandbox\033[0m\n"
printf "  \033[2m%s → %s\033[0m\n\n" "$branch" "$target"

# ── 1. fetch ──────────────────────────────────────────────────────────────────
_run "git fetch origin"
git fetch origin 2>&1 | sed 's/^/     /'
_ok "fetch"

# ── 2. verificar se origin/target existe ─────────────────────────────────────
if ! git ls-remote --exit-code --heads origin "$target" &>/dev/null; then
  _err "origin/$target nao encontrada. Verifique o nome da branch destino."
  exit 1
fi

# ── 3. recriar target local limpo ────────────────────────────────────────────
_run "recriando $target do origin/$target"
git checkout "$current" &>/dev/null 2>&1 || true   # garante saida do target se estiver nele
git branch -D "$target" 2>/dev/null || true
git checkout -b "$target" "origin/$target" --no-track
_ok "$target recriado (limpo)"

# ── 4. merge ──────────────────────────────────────────────────────────────────
_run "git merge $branch --no-edit"
if ! git merge "$branch" --no-edit 2>&1 | sed 's/^/     /'; then
  _err "merge falhou. Resolva os conflitos e rode: git push origin $target"
  git checkout "$current" 2>/dev/null || true
  exit 1
fi
_ok "merge ok"

# ── 5. push ───────────────────────────────────────────────────────────────────
if [[ -z "$no_push" ]]; then
  _run "git push origin $target"
  git push origin "$target" 2>&1 | sed 's/^/     /'
  _ok "push ok"
fi

# ── 6. volta para branch original ─────────────────────────────────────────────
_run "git checkout $current"
git checkout "$current"
_ok "de volta em $current"

printf "\n  \033[32m\033[1mFeito!\033[0m  $branch → $target pushado.\n\n"
