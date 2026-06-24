# lib/seed.sh — popula o banco LOCAL com os dumps de cada app.
# Extensível: para adicionar um app novo (ex: ecommerce), inclua em SEED_APPS
# e escreva uma função seed_<app>().

SEED_APPS=(monolito)

# Lê APP_DIR_MONOLITO do .env do projeto (onde vivem os scripts/0N_*.sql).
app_dir_monolito() {
  local envf
  envf="$(coruja_dir)/.env"
  [[ -f "$envf" ]] || return 1
  grep -E '^APP_DIR_MONOLITO=' "$envf" | head -1 | cut -d= -f2-
}

# Garante o postgres no ar (banco local compartilhado pelos seeds).
# Não usa `up --wait` (o podman-compose não suporta) — sobe e espera a porta 5432 abrir.
# A porta 5432 só aceita conexão DEPOIS do initdb (01_init_db) completar, então é um bom sinal.
_seed_ensure_pg() {
  echo "seed: garantindo o postgres no ar..."
  run_compose up -d postgres || return 1
  echo "seed: aguardando o postgres aceitar conexões na porta 5432..."
  local tries=0
  while [ "$tries" -lt 60 ]; do
    if (exec 3<>/dev/tcp/127.0.0.1/5432) 2>/dev/null; then
      return 0
    fi
    tries=$((tries + 1))
    sleep 2
  done
  echo "seed: postgres não respondeu na porta 5432 a tempo (120s)." >&2
  return 1
}

# monolito: aplica os dumps 02+_*.sql via psql -U root (01_init_db já roda no initdb).
seed_monolito() {
  local mono
  mono="$(app_dir_monolito)" || true
  if [[ -z "${mono:-}" || ! -d "$mono/scripts" ]]; then
    echo "seed[monolito]: APP_DIR_MONOLITO inválido ou sem scripts/ — pulado." >&2
    return 1
  fi
  local f
  for f in "$mono"/scripts/[0-9][0-9]_*.sql; do
    [[ -f "$f" ]] || continue
    case "$(basename "$f")" in 01_*) continue ;; esac
    echo "seed[monolito]: aplicando $(basename "$f")..."
    run_compose exec -T postgres psql -U root < "$f" \
      || echo "seed[monolito]: aviso — falha em $(basename "$f") (segue)" >&2
  done
  echo "seed[monolito]: concluído."
}

# Dispatcher: sobe o postgres uma vez e roda o seed de cada app selecionado.
seed_apps() {
  [[ $# -eq 0 ]] && { echo "seed: nada a fazer."; return 0; }
  _seed_ensure_pg || { echo "seed: postgres não ficou pronto." >&2; return 1; }
  local app
  for app in "$@"; do
    case "$app" in
      monolito) seed_monolito || true ;;
      *) echo "seed: app '$app' não tem seeder definido (ainda)." >&2 ;;
    esac
  done
}
