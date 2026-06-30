# wizard — seleção interativa de ambiente por serviço + compose up.
# É o comando default: `coruja` puro abre este wizard.
# Para relançar a última config sem perguntar, use `coruja up`.

front_env="${args[--front]:-}"
bo_env="${args[--bo]:-}"
mono_sel="${args[--monolito]:-}"
vertical="${args[--vertical]:-}"

no_worker="false"; [[ -n "${args[--no-worker]:-}" ]] && no_worker="true"
detach="false";    [[ -n "${args[--detach]:-}" ]]    && detach="true"
dry_run="false";   [[ -n "${args[--dry-run]:-}" ]]   && dry_run="true"

# Carrega a última config (popula STATE_*); vira o default de cada pergunta.
state_load

# Worktree por app: flag sobrescreve; senão herda o que o `coruja worktrees` salvou (ou main).
MONO_WT="${args[--monolito-worktree]:-${STATE_MONO_WT:-main}}"
BO_WT="${args[--bo-worktree]:-${STATE_BO_WT:-main}}"
FRONT_WT="${args[--front-worktree]:-${STATE_FRONT_WT:-main}}"

# Catálogo — espelha os scripts <ambiente>:<vertical> do package.json do front-student.
FRONT_ENVS=(local sandbox qa prod devbox skip)
VERTICALS=(carreiras-juridicas concursos medicina militares oab vestibulares)

# Flags pré-preenchem: se passou --front, não pergunta o front, e assim por diante.

# --- front-student ---
[[ -z "$front_env" ]] && front_env="$(pick_env 'front-student — ambiente:' "${STATE_FRONT:-local}" "${FRONT_ENVS[@]}")"

# --- bo-container ---
[[ -z "$bo_env" ]] && bo_env="$(pick_env 'bo-container — ambiente:' "${STATE_BO:-local}" local sandbox qa prod skip)"

# --- vertical (só pergunta se algum frontend sobe) ---
if [[ -z "$vertical" ]]; then
  if [[ "$front_env" == "skip" && "$bo_env" == "skip" ]]; then
    vertical="${STATE_VERTICAL:-carreiras-juridicas}"
  else
    vertical="$(pick_env 'vertical:' "${STATE_VERTICAL:-carreiras-juridicas}" "${VERTICALS[@]}")"
  fi
fi

# --- monolito ---
[[ -z "$mono_sel" ]] && mono_sel="$(pick_env 'monolito — ambiente / .env (auto deriva dos frontends):' "${STATE_MONO:-auto}" auto local sandbox sandbox-devbox prod skip)"

if [[ "$mono_sel" == "prod" ]]; then
  echo "⚠ monolito em PROD: tokens/integrações (NewRelic, Sentry, APIs) apontam pra PRODUÇÃO." >&2
  echo "  DB/Redis/localstack continuam locais — mas cuidado com chamadas a sistemas reais." >&2
fi

# --- monolito: modo de execução (só pergunta se o monolito sobe) ---
# normal = hot-reload (CompileDaemon, rebuild via watcher); debug = Delve headless na :2345
# (recompila do zero a cada start do container — anexe com `dlv connect localhost:2345`).
if [[ "$mono_sel" != "skip" ]]; then
  mono_debug_default="normal"
  [[ "${STATE_DEBUG:-0}" == "1" ]] && mono_debug_default="debug"
  mono_debug_sel="$(pick_env 'monolito — execução (normal=hot-reload | debug=Delve :2345):' "$mono_debug_default" normal debug)"
  mono_debug=0
  [[ "$mono_debug_sel" == "debug" ]] && mono_debug=1
fi

# --- worker: parte do wizard, mesmo estilo de seleção ---
if [[ "$no_worker" == "false" ]]; then
  worker_sel="$(pick_env 'monolito-worker (sandbox):' "${STATE_WORKER:-yes}" yes no)"
  [[ "$worker_sel" == "no" ]] && no_worker="true"
fi

# --- pdf-kit: consumer local de PDF do LDI (opt-in, default off). Só com monolito local. ---
pdfkit_sel=""
[[ -n "${args[--pdf-kit]:-}" ]] && pdfkit_sel="yes"
if [[ -z "$pdfkit_sel" && "$mono_sel" != "skip" ]]; then
  pdfkit_sel="$(pick_env 'pdf-kit (gera PDF do LDI local — pesado, exige clone do pdf-kit):' "${STATE_PDFKIT:-no}" no yes)"
fi
pdfkit_sel="${pdfkit_sel:-no}"

# --- modo de execução: foreground (default, segura o terminal/logs) ou background ---
if [[ "$detach" == "true" ]]; then
  run_mode="background"
else
  run_mode="$(pick_env 'modo de execução:' "${STATE_MODE:-foreground}" foreground background)"
fi
RUN_MODE="$run_mode"

auto_down="$(pick_env 'auto-down (desce o stack após esse uptime; off desliga):' "${STATE_AUTODOWN:-1h}" 1h 2h 4h 30m off)"
AUTO_DOWN="$auto_down"

# Globais consumidas por launch_stack (resolve.sh + state_save).
FRONT_ENV="$front_env"
BO_SEL="$bo_env"
MONO_SEL="$mono_sel"
NO_WORKER="$no_worker"
VERTICAL_SEL="$vertical"
WORKER_SEL="${worker_sel:-yes}"
PDFKIT_SEL="$pdfkit_sel"
MONO_DEBUG="${mono_debug:-0}"
# PLUG_DEBUG_APP é lido pelo entrypoint do monolito (1 = dlv debug headless; 0 = CompileDaemon).
# Exportado aqui pra o compose interpolar na criação do container via launch_stack.
export PLUG_DEBUG_APP="$MONO_DEBUG"

launch_stack true "$dry_run"
