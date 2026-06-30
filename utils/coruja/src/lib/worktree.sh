# lib/worktree.sh — descobre e resolve git worktrees dos apps montados no stack.
#
# Modelo (confirmado pela estrutura git do monorepo coruja):
#   • monolito + bo-container vivem DENTRO de worktrees do MONOREPO (mesmo repo) →
#     compartilham a MESMA lista de worktrees.
#   • front-student é submódulo com worktrees PRÓPRIAS → lista separada.
#
# A seleção aponta APP_DIR_MONOLITO / APP_DIR_BO / APP_DIR_FRONT para o worktree
# escolhido (por slug), permitindo subir cada app de um worktree diferente. Slug
# vazio ou "main" = worktree primário (os caminhos APP_DIR_* do .env).
#
# Os caminhos-base vêm do .env; daí derivamos:
#   monorepo root = dirname(dirname(APP_DIR_MONOLITO))   (…/coruja/apps/monolito → …/coruja)
#   front base    = APP_DIR_FRONT                         (…/coruja/apps/front-student)

WT_MAIN_SLUG="main"

# Lê o valor BASE (worktree primário) de APP_DIR_<X> direto do .env, com ~ expandido.
# Lê do .env (não do ambiente) de propósito: o export_env pode já ter sobrescrito a var
# com o worktree escolhido, e aqui precisamos sempre do caminho original.
wt_base_dir() {
  local key="$1"
  local penv val
  penv="$(coruja_dir)/.env"
  [[ -f "$penv" ]] || return 0
  val="$(grep -E "^${key}=" "$penv" | head -1 | cut -d= -f2-)"
  echo "${val/#\~/$HOME}"
}

wt_monorepo_root() {
  local mono_base
  mono_base="$(wt_base_dir APP_DIR_MONOLITO)"
  [[ -z "$mono_base" ]] && return 1
  echo "$(dirname "$(dirname "$mono_base")")"
}

wt_front_base() {
  wt_base_dir APP_DIR_FRONT
}

# Converte a saída --porcelain de `git worktree list` em linhas "slug<TAB>path<TAB>ref".
# slug = basename do path; ref = branch (sem refs/heads/) ou "detached".
# Caminhos relativos (git com extensão relativeworktrees) são normalizados contra <repo>.
wt_parse_porcelain() {
  local repo="$1"
  local path="" branch="" line

  while IFS= read -r line; do
    case "$line" in
      "worktree "*)
        path="${line#worktree }"
        branch=""
        case "$path" in
          /*) ;;
          *) path="$(cd "$repo" >/dev/null 2>&1 && realpath -m "$path" 2>/dev/null || echo "$path")" ;;
        esac
        ;;
      "branch refs/heads/"*)
        branch="${line#branch refs/heads/}"
        ;;
      "detached")
        branch="detached"
        ;;
      "")
        wt_emit_record "$path" "$branch"
        path=""
        ;;
    esac
  done

  # Porcelain encerra cada bloco com linha em branco, mas o último pode não ter — flush.
  wt_emit_record "$path" "$branch"
}

wt_emit_record() {
  local path="$1" branch="$2"
  [[ -z "$path" ]] && return 0
  printf '%s\t%s\t%s\n' "$(basename "$path")" "$path" "${branch:-?}"
}

# Worktrees do monorepo (servem monolito + bo-container). Primeira linha é o primário.
wt_list_monorepo() {
  local root
  root="$(wt_monorepo_root)" || return 0
  [[ -d "$root" ]] || return 0
  git -C "$root" worktree list --porcelain 2>/dev/null | wt_parse_porcelain "$root"
}

# Worktrees do front-student. O primário é sintetizado a partir do APP_DIR_FRONT do .env
# (o `git worktree list` de submódulo reporta o primário pelo gitdir, não pelo checkout) —
# por isso emitimos "main" manualmente e listamos só os worktrees adicionais.
wt_list_front() {
  local base
  base="$(wt_front_base)"
  [[ -z "$base" ]] && return 0

  printf '%s\t%s\t%s\n' "$WT_MAIN_SLUG" "$base" "base"

  [[ -d "$base" ]] || return 0
  local slug path ref
  while IFS=$'\t' read -r slug path ref; do
    # pula o primário: ou aponta pro checkout base, ou pro próprio gitdir (.git/modules/…)
    [[ "$path" == "$base" ]] && continue
    case "$path" in
      */.git/*) continue ;;
    esac
    printf '%s\t%s\t%s\n' "$slug" "$path" "$ref"
  done < <(git -C "$base" worktree list --porcelain 2>/dev/null | wt_parse_porcelain "$base")
}

# Resolve o slug de um worktree para o diretório do app, pronto pra virar APP_DIR_*.
# Vazio / "main" → caminho-base do .env. Slug inválido → avisa e cai na base.
wt_resolve_monorepo_app() {
  local slug="$1" subdir="$2" base_key="$3"
  if [[ -z "$slug" || "$slug" == "$WT_MAIN_SLUG" ]]; then
    wt_base_dir "$base_key"
    return
  fi

  local path
  path="$(wt_list_monorepo | awk -F'\t' -v s="$slug" '$1 == s && !found { print $2; found = 1 }')"
  if [[ -z "$path" ]]; then
    echo "! worktree '$slug' não encontrado no monorepo — usando o base." >&2
    wt_base_dir "$base_key"
    return
  fi
  echo "$path/apps/$subdir"
}

wt_resolve_front_app() {
  local slug="$1"
  if [[ -z "$slug" || "$slug" == "$WT_MAIN_SLUG" ]]; then
    wt_front_base
    return
  fi

  local path
  path="$(wt_list_front | awk -F'\t' -v s="$slug" '$1 == s && !found { print $2; found = 1 }')"
  if [[ -z "$path" ]]; then
    echo "! worktree '$slug' não encontrado no front-student — usando o base." >&2
    wt_front_base
    return
  fi
  echo "$path"
}

# Rótulo curto pra exibir a escolha no plano (vazio/main → "main").
wt_label() {
  local slug="$1"
  echo "${slug:-$WT_MAIN_SLUG}"
}
