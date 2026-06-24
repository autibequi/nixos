# lib/checks.sh — doctor (pré-requisitos) + ensure_certs.

CORUJA_HOSTS=(
  "local.estrategia-sandbox.com.br"
  "admin.local.estrategia-sandbox.com.br"
  "api.local.estrategia-sandbox.com.br"
  "perfil.local.estrategia-sandbox.com.br"
)

_ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
_warn() { printf "  \033[33m!\033[0m %s\n" "$1"; }
_err()  { printf "  \033[31m✗\033[0m %s\n" "$1"; }

_check_compose() {
  local cc
  if cc="$(compose_cmd)"; then
    _ok "compose: $cc"
  else
    _err "compose ausente (docker compose / docker-compose / podman-compose)"
  fi
}

_check_mkcert() {
  if command -v mkcert >/dev/null 2>&1; then
    _ok "mkcert instalado"
  else
    _warn "mkcert ausente — necessário p/ gerar os certs TLS"
  fi
}

_check_certs() {
  local dir
  dir="$(coruja_dir)"
  if [[ -f "$dir/certs/fullchain.pem" ]]; then
    _ok "certs TLS presentes (certs/fullchain.pem)"
  else
    _warn "certs ausentes — serão gerados pelo 'coruja install' (ou scripts/gen-cert.sh)"
  fi
}

_check_npmrc() {
  if [[ -f "$HOME/.npmrc" ]] && grep -q "_authToken" "$HOME/.npmrc" 2>/dev/null; then
    # shellcheck disable=SC2088  # til é texto de UI, não path a expandir
    _ok "~/.npmrc com token GitHub Packages"
  else
    # shellcheck disable=SC2088
    _err "~/.npmrc sem _authToken p/ npm.pkg.github.com (@estrategiahq/* falha com 401)"
  fi
}

_check_ssh() {
  if ls "$HOME"/.ssh/id_* >/dev/null 2>&1; then
    _ok "chave SSH ~/.ssh/id_* presente"
  else
    # shellcheck disable=SC2088
    _warn "~/.ssh/id_* ausente — GOPRIVATE github.com/estrategiahq/* pode falhar"
  fi
}

_check_hosts() {
  local missing=() h
  for h in "${CORUJA_HOSTS[@]}"; do
    grep -qE "[[:space:]]${h}([[:space:]]|\$)" /etc/hosts 2>/dev/null || missing+=("$h")
  done
  if [[ ${#missing[@]} -eq 0 ]]; then
    _ok "/etc/hosts com as entradas *.local.estrategia-sandbox.com.br"
  else
    _warn "/etc/hosts faltando entradas — adicione (precisa sudo):"
    local m
    for m in "${missing[@]}"; do
      echo "        127.0.0.1   $m"
    done
  fi
}

_check_env_file() {
  local dir
  dir="$(coruja_dir)"
  if [[ -f "$dir/.env" ]]; then
    _ok ".env presente"
  else
    _warn ".env ausente — copie de .env.example e ajuste APP_DIR_MONOLITO/BO/FRONT"
  fi
}

doctor_run() {
  echo "coruja doctor — pré-requisitos:"
  _check_compose
  _check_mkcert
  _check_certs
  _check_npmrc
  _check_ssh
  _check_hosts
  _check_env_file
  echo
}

# Gera os certs se faltarem (chamado pelo up/install/debug).
ensure_certs() {
  local dir
  dir="$(coruja_dir)"
  if [[ ! -f "$dir/certs/fullchain.pem" ]]; then
    echo "certs ausentes — gerando via scripts/gen-cert.sh..."
    ( cd "$dir" && bash scripts/gen-cert.sh )
  fi
}
