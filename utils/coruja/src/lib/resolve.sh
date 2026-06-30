# lib/resolve.sh — traduz o ambiente escolhido por serviço em (1) lista de
# serviços a subir e (2) variáveis de ambiente do compose.
#
# Entradas (globais, setadas pelo up_command):
#   FRONT_ENV    local | sandbox | skip
#   BO_SEL       local | sandbox | skip
#   MONO_SEL     auto  | local   | sandbox | prod | skip
#   NO_WORKER    true | false
#   VERTICAL_SEL <vertical>
#
# Saídas:
#   RESOLVED_SERVICES  array com os serviços resolvidos
#   export de NPM_SCRIPT_ENV / BFF_URL / BO_ENV / MONO_ENV / VERTICAL

resolve_services() {
  RESOLVED_SERVICES=()

  # backend local sobe se o monolito for pedido explicitamente (local/sandbox/prod),
  # ou (em auto) se algum frontend roda em local.
  local backend_local="false"
  case "$MONO_SEL" in
    skip)               backend_local="false" ;;
    local | sandbox | sandbox-devbox | prod) backend_local="true" ;;
    *) # auto: sobe o backend se algum frontend aponta pro BFF local
      #         (front local/devbox apontam api.local; bo local idem)
      if [[ "$FRONT_ENV" == "local" || "$FRONT_ENV" == "devbox" || "$BO_SEL" == "local" ]]; then
        backend_local="true"
      fi
      ;;
  esac

  [[ "$FRONT_ENV" != "skip" ]] && RESOLVED_SERVICES+=("front-student")
  [[ "$BO_SEL"   != "skip" ]] && RESOLVED_SERVICES+=("bo-container")

  # reverseproxy termina o TLS dos frontends — sobe se algum frontend sobe.
  if [[ "$FRONT_ENV" != "skip" || "$BO_SEL" != "skip" ]]; then
    RESOLVED_SERVICES+=("reverseproxy")
  fi

  if [[ "$backend_local" == "true" ]]; then
    RESOLVED_SERVICES+=("postgres" "monolito-redis" "localstack" "monolito")
    if [[ "$NO_WORKER" != "true" ]]; then
      RESOLVED_SERVICES+=("monolito-worker")
    fi
    # pdf-kit: consumer local de PDF do LDI (Playwright). Opt-in (default off) — pesado e
    # exige o clone ./pdf-kit. Só faz sentido com backend local (consome filas do LocalStack).
    if [[ "$PDFKIT_SEL" == "yes" ]]; then
      RESOLVED_SERVICES+=("pdf-kit")
    fi
  fi

  # Importante: o bashly roda sob `set -e`. Sem este return, se a última
  # expressão acima for falsa a função retorna 1 e aborta o script.
  return 0
}

# APP_ENV que o monolito carrega (deriva de MONO_SEL). É a chave dos blocos nos
# config_*.yaml. auto/skip → local; sandbox → sandbox; sandbox-devbox → sandbox-devbox
# (serviços sandbox + SQS/S3 no LocalStack); prod → prod.
mono_env() {
  case "$MONO_SEL" in
    sandbox)        echo "sandbox" ;;
    sandbox-devbox) echo "sandbox-devbox" ;;
    prod)           echo "prod" ;;
    *)              echo "local" ;;
  esac
}

# Arquivo .env que o compose carrega (env_file). Igual ao APP_ENV, exceto
# sandbox-devbox, que reaproveita o .env.sandbox (credenciais/tokens do sandbox).
mono_env_file() {
  local e
  e="$(mono_env)"
  [[ "$e" == "sandbox-devbox" ]] && e="sandbox"
  echo "$e"
}

export_env() {
  export VERTICAL="${VERTICAL_SEL:-carreiras-juridicas}"

  # Porta interna do Nuxt do front-student: cada script npm <env>:<vertical> fixa uma
  # porta própria via cross-env (concursos=3000 … carreiras-juridicas=3005). O nginx
  # (upstream) e o publish do container precisam acompanhar, senão dá 502.
  case "$VERTICAL" in
    concursos)           export FRONT_PORT=3000 ;;
    medicina)            export FRONT_PORT=3001 ;;
    militares)           export FRONT_PORT=3002 ;;
    oab)                 export FRONT_PORT=3003 ;;
    vestibulares)        export FRONT_PORT=3004 ;;
    carreiras-juridicas) export FRONT_PORT=3005 ;;
    *)                   export FRONT_PORT=3005 ;;
  esac

  # MONO_ENV chaveia o env_file (.env.<X>) e o APP_ENV do monolito/worker no compose.
  local me
  me="$(mono_env)"
  export MONO_ENV="$me"

  # sandbox-devbox = serviços do sandbox + SQS/S3 no LocalStack. O APP_ENV (MONO_ENV)
  # fica sandbox-devbox (seleciona os blocos sandbox-devbox no config), mas credenciais,
  # tokens e banco reaproveitam o sandbox: o env_file e o SHARED_DB_* usam "sandbox".
  # MONO_ENV_FILE desacopla o arquivo .env do APP_ENV (o compose lê MONO_ENV_FILE).
  local db_env
  db_env="$(mono_env_file)"
  export MONO_ENV_FILE="$db_env"

  # APP_DIR_* no shell com worktree aplicado e ~ já expandido. Duas razões pra resolver aqui:
  #   1. worktree: aponta cada app pro worktree escolhido (slug "main"/vazio = base do .env);
  #   2. tilde: o podman-compose não expande ~ em valores do .env — precisa chegar via env.
  # wt_resolve_* já lê o base do .env e expande ~, então cobre o caso "main" também.
  export APP_DIR_MONOLITO="$(wt_resolve_monorepo_app "${MONO_WT:-}" monolito APP_DIR_MONOLITO)"
  export APP_DIR_BO="$(wt_resolve_monorepo_app "${BO_WT:-}" bo-container APP_DIR_BO)"
  export APP_DIR_FRONT="$(wt_resolve_front_app "${FRONT_WT:-}")"
  local _app_dir="$APP_DIR_MONOLITO"

  # Para sandbox/prod: exporta SHARED_DB_* do .env.<X> pra o shell, para que o
  # docker-compose.yml (que usa ${SHARED_DB_HOST:-postgres}) receba os valores corretos.
  # O environment: do compose sobrescreve env_file — essa é a única forma de passar vars
  # do .env.sandbox sem hardcodar credenciais no compose.
  if [[ "$db_env" == "sandbox" || "$db_env" == "prod" ]]; then
    local mono_dir="$_app_dir"

    local env_file="${mono_dir}/.env.${db_env}"
    if [[ -f "$env_file" ]]; then
      local key val
      while IFS='=' read -r key val; do
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        case "$key" in
          SHARED_DB_HOST | SHARED_DB_PORT | SHARED_DB_USERNAME | \
          SHARED_DB_PASSWORD | SHARED_DB_URL | \
          PDF_SYSTEM_TOKEN | GLOBAL_SYSTEM_TOKENS)
            # PDF_SYSTEM_TOKEN/GLOBAL_SYSTEM_TOKENS: o docker-compose.pdfkit.yaml interpola
            # estes pro consumer pdf-kit (PDFKIT_SYSTEM_TOKEN / GLOBAL_SYSTEM_TOKEN). Sem eles
            # o pdf-kit erra o check de long_running e abandona a mensagem.
            export "$key=$val"
            ;;
        esac
      done < "$env_file"
    fi

    # RDS exige SSL. O compose tem default false — apenas garantir que não haja
    # DISABLE_DB_SSL=true herdado do shell (o Go code trata qualquer string não-vazia como truthy).
    unset DISABLE_DB_SSL
  else
    # Local: postgres sem TLS → precisa sslmode=disable.
    export DISABLE_DB_SSL=true
  fi

  # O script npm do front (cross-env) já fixa BFF_URL/DEFAULT_VERTICAL pelo nome
  # <ambiente>:<vertical>; o que importa é NPM_SCRIPT_ENV (ambiente) + VERTICAL.
  # O BFF_URL abaixo é coerência/doc (o script sobrescreve de qualquer jeito).
  if [[ "$FRONT_ENV" != "skip" ]]; then
    export NPM_SCRIPT_ENV="$FRONT_ENV"
    case "$FRONT_ENV" in
      local | devbox) export BFF_URL="https://api.local.estrategia-sandbox.com.br/" ;;
      sandbox)        export BFF_URL="https://api.estrategia-sandbox.com.br/" ;;
      qa)             export BFF_URL="https://api.estrategia-qa.com.br/" ;;
      prod)           export BFF_URL="https://api.estrategia.com/" ;;
    esac
  fi

  # bo-container: BO_ENV escolhe o bloco do .env-cmdrc.js (serve:<env>).
  if [[ "$BO_SEL" != "skip" ]]; then
    export BO_ENV="$BO_SEL"
  fi

  # pdf-kit local: o Chromium do consumer confia no cert mkcert (rootCA montado via
  # MKCERT_CAROOT) e o repo precisa estar clonado em APP_DIR_PDFKIT. Só quando pedido.
  if [[ "$PDFKIT_SEL" == "yes" ]]; then
    export MKCERT_CAROOT="$(default_mkcert_caroot)"
    # APP_DIR_PDFKIT expandido (podman-compose não expande ~) — build context do consumer.
    local _pdf_dir="${APP_DIR_PDFKIT:-}"
    if [[ -z "$_pdf_dir" ]]; then
      local _penv2; _penv2="$(coruja_dir)/.env"
      [[ -f "$_penv2" ]] && _pdf_dir="$(grep -E '^APP_DIR_PDFKIT=' "$_penv2" | head -1 | cut -d= -f2-)"
    fi
    _pdf_dir="${_pdf_dir/#\~/$HOME}"
    export APP_DIR_PDFKIT="$_pdf_dir"
    ensure_pdfkit_clone
  fi
}

# ensure_pdfkit_clone — garante o clone de estrategiahq/pdf-kit em APP_DIR_PDFKIT (build
# context do docker-compose.pdfkit.yaml). Clona na primeira vez; não falha o up se o git
# falhar (avisa e segue — o compose dará erro claro de build se faltar).
ensure_pdfkit_clone() {
  local dir="${APP_DIR_PDFKIT}"
  [[ -d "$dir/.git" ]] && return 0
  echo "→ pdf-kit: clonando estrategiahq/pdf-kit em $dir (primeira vez)…"
  if ! git clone git@github.com:estrategiahq/pdf-kit.git "$dir" 2>/dev/null; then
    echo "! pdf-kit: falha ao clonar. Rode ./scripts/pdf-kit-setup.sh manualmente (precisa de acesso ao repo privado)." >&2
  fi
  return 0
}

# Reconstrói as globais do wizard (FRONT_ENV/BO_SEL/MONO_SEL/NO_WORKER/VERTICAL_SEL/RUN_MODE)
# a partir do state salvo pelo último `up` e re-exporta o ambiente.
# Comandos que recriam containers fora do wizard (restart, debug) PRECISAM chamar isto,
# senão o container recriado cai nos defaults do compose (vertical, ambiente, SSL, BFF).
load_env_from_state() {
  state_load
  FRONT_ENV="${STATE_FRONT:-local}"
  BO_SEL="${STATE_BO:-local}"
  MONO_SEL="${STATE_MONO:-auto}"
  VERTICAL_SEL="${STATE_VERTICAL:-carreiras-juridicas}"
  RUN_MODE="${STATE_MODE:-foreground}"
  WORKER_SEL="${STATE_WORKER:-yes}"
  NO_WORKER="false"
  [[ "$WORKER_SEL" == "no" ]] && NO_WORKER="true"
  # pdf-kit: opt-in persistido (default off). Relança junto se o último up subiu o consumer.
  PDFKIT_SEL="${STATE_PDFKIT:-no}"
  # debug do monolito (Delve) persistido pelo wizard — re-exporta pra o compose interpolar
  # na recriação do container (up/restart). Sem isto, recriar cairia no default (CompileDaemon).
  MONO_DEBUG="${STATE_DEBUG:-0}"
  AUTO_DOWN="${STATE_AUTODOWN:-1h}"
  # Worktree por app (slug; vazio/main = base). export_env aplica em APP_DIR_*.
  MONO_WT="${STATE_MONO_WT:-main}"
  BO_WT="${STATE_BO_WT:-main}"
  FRONT_WT="${STATE_FRONT_WT:-main}"
  export PLUG_DEBUG_APP="$MONO_DEBUG"
  export_env
}

# Sufixo "[wt: <slug>]" pro plano — vazio quando o app usa o worktree primário (main).
plan_wt_suffix() {
  local slug="$1"
  if [[ -z "$slug" || "$slug" == "main" ]]; then
    echo ""
    return
  fi
  echo "  [wt: $slug]"
}

print_plan() {
  echo
  echo "Ambiente escolhido:"
  printf "  front-student : %s%s\n" "$FRONT_ENV" "$(plan_wt_suffix "${FRONT_WT:-}")"
  printf "  bo-container  : %s%s\n" "$BO_SEL" "$(plan_wt_suffix "${BO_WT:-}")"
  printf "  vertical      : %s\n" "$VERTICAL_SEL"
  if [[ "$MONO_SEL" == "skip" ]]; then
    printf "  monolito      : skip\n"
  else
    local _dbg=""
    [[ "${MONO_DEBUG:-0}" == "1" ]] && _dbg="  [debug: Delve :2345]"
    printf "  monolito      : %s  (APP_ENV=%s, .env.%s)%s%s\n" "$MONO_SEL" "$(mono_env)" "$(mono_env_file)" "$_dbg" "$(plan_wt_suffix "${MONO_WT:-}")"
  fi
  printf "  modo          : %s\n" "${RUN_MODE:-foreground}"
  printf "  auto-down     : %s\n" "${AUTO_DOWN:-1h}"
  echo
  echo "Serviços que vão subir:"
  if [[ ${#RESOLVED_SERVICES[@]} -eq 0 ]]; then
    echo "  (nenhum)"
  else
    local s
    for s in "${RESOLVED_SERVICES[@]}"; do
      echo "  • $s"
    done
  fi
  echo
}
