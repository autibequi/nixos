# up — relança a última config (.coruja-state) sem perguntar nada.
# Flags sobrescrevem itens específicos, mantendo o resto da última config.
# Para escolher interativamente, rode `coruja` puro (wizard).

dry_run="false"; [[ -n "${args[--dry-run]:-}" ]] && dry_run="true"

# Base = última config salva pelo wizard (popula FRONT_ENV/BO_SEL/MONO_SEL/...).
load_env_from_state

# Overrides pontuais por flag.
[[ -n "${args[--front]:-}" ]]    && FRONT_ENV="${args[--front]}"
[[ -n "${args[--bo]:-}" ]]       && BO_SEL="${args[--bo]}"
[[ -n "${args[--monolito]:-}" ]] && MONO_SEL="${args[--monolito]}"
[[ -n "${args[--vertical]:-}" ]] && VERTICAL_SEL="${args[--vertical]}"
if [[ -n "${args[--no-worker]:-}" ]]; then NO_WORKER="true"; WORKER_SEL="no"; fi
[[ -n "${args[--pdf-kit]:-}" ]]    && PDFKIT_SEL="yes"
[[ -n "${args[--no-pdf-kit]:-}" ]] && PDFKIT_SEL="no"
[[ -n "${args[--detach]:-}" ]]   && RUN_MODE="background"

launch_stack false "$dry_run"
