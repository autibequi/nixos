# seed — popula o banco LOCAL com os dumps. Wizard escolhe os apps (extensível).

selected=()
if [[ -n "${args[--yes]:-}" ]]; then
  selected=("${SEED_APPS[@]}")
else
  while IFS= read -r line; do
    [[ -n "$line" ]] && selected+=("$line")
  done < <(pick_multi 'rodar seed no banco LOCAL de quais apps?' "${SEED_APPS[@]}")
fi

if [[ ${#selected[@]} -eq 0 ]]; then
  echo "nada selecionado."
  exit 0
fi

seed_apps "${selected[@]}"
