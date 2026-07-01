# install — bootstrap: doctor + deps dos apps escolhidos + certs.
# Não builda imagem (rode `coruja build [service]` antes se ainda não buildou —
# senão o `run_compose run` builda implicitamente na primeira vez, mas sem cache
# de layer otimizado pro fluxo de install).

doctor_run

# Quais apps instalar deps. Default: todos. --yes pula o wizard.
APPS_ALL=(bo-container front-student monolito)
selected=()

if [[ -n "${args[--yes]:-}" ]]; then
  selected=("${APPS_ALL[@]}")
else
  while IFS= read -r line; do
    [[ -n "$line" ]] && selected+=("$line")
  done < <(pick_multi 'quais apps instalar deps?' "${APPS_ALL[@]}")
fi

if [[ ${#selected[@]} -eq 0 ]]; then
  echo "nada selecionado — só gerando os certs."
else
  echo "apps selecionados: ${selected[*]}"
fi

for app in "${selected[@]}"; do
  case "$app" in
    bo-container | front-student)
      echo "==> bun install ($app)"
      run_compose run --rm --no-deps "$app" bun install
      ;;
    monolito)
      echo "==> go mod download (monolito)"
      run_compose run --rm --no-deps monolito sh -c 'cd /go/apps/monolito && go mod download' \
        || echo "aviso: go mod download falhou (segue — o entrypoint re-tenta no boot)"
      ;;
  esac
done

echo "==> certs TLS"
ensure_certs

echo
echo "bootstrap pronto."
echo "  • popular o banco local:  coruja seed"
echo "  • subir a stack:          coruja up"
