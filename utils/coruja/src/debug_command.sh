# debug — sobe monolito/worker com Delve headless.

target="${args[target]:-app}"

# Recarrega a config do último `up` — senão o monolito recriado perderia o ambiente
# escolhido (ex: debugar apontado pra sandbox cairia silenciosamente no DB local).
load_env_from_state

ensure_certs

case "$target" in
  app)
    export PLUG_DEBUG_APP=1
    run_compose up -d --force-recreate monolito
    # Recriar o monolito troca o IP → o nginx (que cacheia o upstream no boot) fica stale e
    # devolve 502 em tudo via monolito. Re-resolve recriando o proxy DEPOIS, com o monolito no ar.
    run_compose up -d --no-deps --force-recreate reverseproxy
    echo "Delve (monolito) headless em :2345 — conecte com: dlv connect localhost:2345"
    echo "rebuild: re-rode 'coruja debug' (dlv recompila do zero + re-resolve o nginx)."
    ;;
  worker)
    export PLUG_DEBUG_WORKER=1
    run_compose up -d --force-recreate monolito-worker
    echo "Delve (worker) headless em :2346 — conecte com: dlv connect localhost:2346"
    ;;
  *)
    echo "alvo inválido: '$target' (use app | worker)" >&2
    exit 1
    ;;
esac
