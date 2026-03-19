# Determina o comando padrão por tipo de servico
service="${args[service]}"
cmd="${args[--cmd]:-}"
worktree="${args[--worktree]:-}"

if [[ -z "$cmd" ]]; then
  case "$service" in
    monolito) cmd="make test-ldi" ;;
    *)        cmd="yarn test" ;;
  esac
fi

_zion_dk_shell "$service" "app" "$cmd" "$worktree"
