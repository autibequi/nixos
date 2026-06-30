# worktrees — lista os worktrees disponíveis e deixa escolher 1 por app, persistindo no
# state. Plain `coruja` / `coruja up` depois sobem com a escolha salva.
#
# monolito + bo-container puxam do MESMO conjunto (worktrees do monorepo); front-student
# tem lista própria (worktrees do submódulo). "main" = worktree primário (APP_DIR_* do .env).

state_load

# Conjunto do monorepo: o primeiro registro do `git worktree list` é sempre o primário —
# apresentamos como "main" e oferecemos os demais worktrees pelo slug real.
mapfile -t mono_all < <(wt_list_monorepo | cut -f1)
mono_opts=("$WT_MAIN_SLUG")
for slug in "${mono_all[@]:1}"; do
  mono_opts+=("$slug")
done

# Front-student: wt_list_front já emite "main" e pula o primário, então usamos direto.
mapfile -t front_opts < <(wt_list_front | cut -f1)
[[ ${#front_opts[@]} -eq 0 ]] && front_opts=("$WT_MAIN_SLUG")

print_worktree_list() {
  echo
  echo "Worktrees do monorepo (monolito + bo-container):"
  print_worktree_group "$(wt_list_monorepo)" "${STATE_MONO_WT:-$WT_MAIN_SLUG}" "${STATE_BO_WT:-$WT_MAIN_SLUG}"
  echo
  echo "Worktrees do front-student:"
  print_worktree_group "$(wt_list_front)" "${STATE_FRONT_WT:-$WT_MAIN_SLUG}"
  echo
}

# Imprime as linhas de um grupo, marcando com ● o(s) worktree(s) selecionado(s) no state.
# O primário do monorepo aparece como "main" (primeira linha).
print_worktree_group() {
  local rows="$1"; shift
  local selected=("$@")
  local first="true"
  local slug path ref display sel mark

  while IFS=$'\t' read -r slug path ref; do
    [[ -z "$slug" ]] && continue
    display="$slug"
    if [[ "$first" == "true" ]]; then
      display="$WT_MAIN_SLUG"
      first="false"
    fi
    mark=" "
    for sel in "${selected[@]}"; do
      [[ "$sel" == "$display" ]] && mark="●"
    done
    printf "  %s %-30s [%s]\n" "$mark" "$display" "$ref"
  done <<< "$rows"
}

print_worktree_list

mono_sel="$(pick_env 'monolito — worktree:'     "${STATE_MONO_WT:-$WT_MAIN_SLUG}"  "${mono_opts[@]}")"
bo_sel="$(pick_env 'bo-container — worktree:'   "${STATE_BO_WT:-$WT_MAIN_SLUG}"    "${mono_opts[@]}")"
front_sel="$(pick_env 'front-student — worktree:' "${STATE_FRONT_WT:-$WT_MAIN_SLUG}" "${front_opts[@]}")"

state_save_worktrees "$mono_sel" "$bo_sel" "$front_sel"

echo
echo "✓ worktrees salvos:"
printf "  monolito     → %s\n" "$mono_sel"
printf "  bo-container → %s\n" "$bo_sel"
printf "  front-student → %s\n" "$front_sel"
echo
echo "Suba com a escolha: coruja up   (ou coruja, pro wizard)"
