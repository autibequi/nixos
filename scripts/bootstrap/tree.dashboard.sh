#!/usr/bin/env bash
# tree.dashboard.sh — workspace tree até depth 2

echo -e "${P_CYAN}${B}  /workspace/${R}"

render_tree() {
  local base="$1"
  # Lista dirs e arquivos de nível 1, excluindo ocultos e pasta obsidian
  local entries
  mapfile -t entries < <(
    find "$base" -maxdepth 1 -mindepth 1 \
      ! -name '.*' \
      | sort
  )

  local total="${#entries[@]}"
  local limit=$(( total > 10 ? 10 : total ))
  local i=0
  for entry in "${entries[@]}"; do
    i=$(( i + 1 ))
    [[ $i -gt 10 ]] && break
    local name; name="$(basename "$entry")"
    local is_last=0
    [[ $i -eq $limit && $total -le 10 ]] && is_last=1
    [[ $i -eq 10 && $total -gt 10 ]] && is_last=1

    local branch="├──" pad="│   "
    [[ $is_last -eq 1 ]] && branch="└──" && pad="    "

    if [[ -L "$entry" ]]; then
      local target; target="$(readlink "$entry")"
      printf "  ${GRAY}%s${R} ${CYAN}%s${R}${GRAY} -> %s${R}\n" "$branch" "$name" "$target"
    elif [[ -d "$entry" ]]; then
      printf "  ${GRAY}%s${R} ${P_CYAN}%s/${R}\n" "$branch" "$name"
      # Nível 2
      local sub_entries
      mapfile -t sub_entries < <(
        find "$entry" -maxdepth 1 -mindepth 1 \
          ! -name '.*' ! -name 'logs' \
          | sort
      )
      local stotal="${#sub_entries[@]}"
      local slimit=$(( stotal > 10 ? 10 : stotal ))
      local si=0
      for sub in "${sub_entries[@]}"; do
        si=$(( si + 1 ))
        [[ $si -gt 10 ]] && break
        local sname; sname="$(basename "$sub")"
        local sbranch="├──"
        [[ $si -eq $slimit && $stotal -le 10 ]] && sbranch="└──"
        [[ $si -eq 10 && $stotal -gt 10 ]] && sbranch="└──"

        if [[ -L "$sub" ]]; then
          local starget; starget="$(readlink "$sub")"
          printf "  ${GRAY}%s%s${R} ${GREEN}%s${R}${GRAY} -> %s${R}\n" "$pad" "$sbranch" "$sname" "$starget"
        elif [[ -d "$sub" ]]; then
          local count; count=$(find "$sub" -maxdepth 1 -mindepth 1 ! -name '.*' 2>/dev/null | wc -l)
          printf "  ${GRAY}%s%s${R} ${GREEN}%s/${R}${GRAY} [%d]${R}\n" "$pad" "$sbranch" "$sname" "$count"
        else
          printf "  ${GRAY}%s%s${R} %s\n" "$pad" "$sbranch" "$sname"
        fi
      done
      [[ $stotal -gt 10 ]] && printf "  ${GRAY}%s${P_DIM}  ... +%d itens${R}\n" "$pad" $(( stotal - 10 ))
    else
      printf "  ${GRAY}%s${R} %s\n" "$branch" "$name"
    fi
  done
  [[ $total -gt 10 ]] && printf "  ${P_DIM}└──   ... +%d itens${R}\n" $(( total - 10 ))
}

render_tree "$WS"
echo -e "${P_DIM}$(printf '─%.0s' $(seq 1 80))${R}"
