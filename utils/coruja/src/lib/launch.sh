# lib/launch.sh — núcleo compartilhado entre `wizard` (interativo) e `up` (não-interativo).
#
# Espera as globais já setadas pelo chamador:
#   FRONT_ENV BO_SEL MONO_SEL NO_WORKER VERTICAL_SEL WORKER_SEL RUN_MODE
#
# launch_stack <interactive> <dry_run>
#   interactive=true → pede confirmação antes de subir (wizard)
#   dry_run=true     → mostra o plano e não sobe nada
launch_stack() {
  local interactive="${1:-false}"
  local dry_run="${2:-false}"

  resolve_services
  export_env
  print_plan

  if [[ "$dry_run" == "true" ]]; then
    echo "(dry-run) nada foi subido."
    return 0
  fi

  if [[ ${#RESOLVED_SERVICES[@]} -eq 0 ]]; then
    echo "Nada a subir (tudo em skip)."
    return 0
  fi

  if [[ "$interactive" == "true" ]]; then
    confirm "Subir esses serviços?" || { echo "abortado."; return 0; }
  fi

  # Persiste a config — vira o default do wizard e o que o `coruja up` relança.
  state_save

  # certs só importam se o reverseproxy entra na jogada.
  case " ${RESOLVED_SERVICES[*]} " in
    *" reverseproxy "*) ensure_certs ;;
  esac

  # Classifica os serviços em 4 grupos:
  #   proxy   → reverseproxy (nginx)      — sempre --force-recreate (re-templata ${FRONT_PORT})
  #   infra   → postgres/redis/localstack — background, reusa container existente
  #   backend → monolito/worker (Go)      — sempre restart no up (rebuild via entrypoint, ver abaixo)
  #   apps    → frontends + backend       — foreground (ou background no modo -d); attach/reuso
  # backend entra TAMBÉM em apps pra o attach de logs no foreground; o recreate é feito no
  # passo dedicado, então o `up apps` posterior é no-op pro backend já recriado.
  local _proxy=() _infra=() _backend=() _apps=() _consumer=() _svc
  for _svc in "${RESOLVED_SERVICES[@]}"; do
    case "$_svc" in
      reverseproxy)                           _proxy+=("$_svc") ;;
      postgres | monolito-redis | localstack) _infra+=("$_svc") ;;
      monolito | monolito-worker)             _backend+=("$_svc"); _apps+=("$_svc") ;;
      # pdf-kit: consumer (Playwright). Sempre background + --build (imagem do ./pdf-kit),
      # nunca reanexado no foreground (é long-running, polui os logs dos apps).
      pdf-kit)                                _consumer+=("$_svc") ;;
      *)                                      _apps+=("$_svc") ;;
    esac
  done

  # --no-deps: a CLI já resolveu TODAS as deps necessárias. Sem isso, o compose puxaria
  # serviços ligados via depends_on (ex: front-student → monolito) mesmo marcados como skip.
  #
  # ⚠️ ORDEM importa por causa do nginx: o reverseproxy resolve os upstreams (monolito/
  # frontends) UMA vez no boot e CACHEIA o IP. Se ele subir antes dos apps — ou antes do
  # restart do backend — fica com IP velho → 502 em tudo que passa pelo monolito (inclusive
  # /health e o /v3/contents do front-student). Por isso o proxy é (re)criado por ÚLTIMO,
  # depois que todos os upstreams estão no ar com IP final. Recriar também re-templata o
  # ${FRONT_PORT} no envsubst do nginx (continua valendo pra troca de vertical).
  #
  # backend Go: restart re-roda o entrypoint → CompileDaemon faz `go build` do source bind-
  # montado (hot-reload via inotify não é confiável sobre bind-mount → reiniciar = rebuild).
  # restart e NÃO --force-recreate: o podman-compose não passa --replace ao podman → colide
  # nome ("already in use") + deixa órfão. Frontends reusam container (watch próprio).
  # auto-down por uptime — config persistida no state, o quickstart (up) relança junto
  autodown_schedule "${AUTO_DOWN:-1h}"
  if [[ "$RUN_MODE" == "background" ]]; then
    [[ ${#_infra[@]}    -gt 0 ]] && run_compose up -d --no-deps "${_infra[@]}"
    [[ ${#_consumer[@]} -gt 0 ]] && run_compose up -d --no-deps --build "${_consumer[@]}"
    [[ ${#_apps[@]}     -gt 0 ]] && run_compose up -d --no-deps "${_apps[@]}"
    [[ ${#_backend[@]}  -gt 0 ]] && run_compose restart "${_backend[@]}"
    [[ ${#_proxy[@]}   -gt 0 ]] && run_compose up -d --no-deps --force-recreate "${_proxy[@]}"
    echo "subido em background.  logs: coruja logs   |   status: coruja status"
    # Ao subir em background, abre o lazydocker na sequência pra acompanhar o boot.
    # Não-fatal: o stack já está no ar; se faltar lazydocker/socket/TTY, só avisa e segue.
    coruja_open_monitor || true
  else
    if [[ ${#_infra[@]} -gt 0 ]]; then
      echo "subindo infra em background: ${_infra[*]}"
      run_compose up -d --no-deps "${_infra[@]}"
    fi
    # pdf-kit (consumer) sempre em background + build, mesmo no modo foreground.
    [[ ${#_consumer[@]} -gt 0 ]] && run_compose up -d --no-deps --build "${_consumer[@]}"
    # Sobe os apps em background (cria monolito+frontends), rebuilda o backend e recria o
    # proxy por ÚLTIMO (todos resolvidos) — só então reanexa no foreground pros logs.
    [[ ${#_apps[@]}    -gt 0 ]] && run_compose up -d --no-deps "${_apps[@]}"
    [[ ${#_backend[@]} -gt 0 ]] && run_compose restart "${_backend[@]}"
    [[ ${#_proxy[@]}   -gt 0 ]] && run_compose up -d --no-deps --force-recreate "${_proxy[@]}"

    if [[ ${#_apps[@]} -gt 0 ]]; then
      echo "anexando logs dos apps em foreground — Ctrl+C derruba os apps (infra continua rodando)."
      run_compose up --no-deps "${_apps[@]}"
    else
      echo "infra subida em background.  logs: coruja logs   |   status: coruja status"
    fi
  fi
}
