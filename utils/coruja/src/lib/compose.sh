# lib/compose.sh — localização do projeto + backend de compose.

# Diretório onde vive o docker-compose.yml. Resolve nesta ordem:
#   1. $CORUJA_DIR (override explícito).
#   2. O diretório do próprio script, se houver um docker-compose.yml ao lado
#      (caso o binário rode de dentro do projeto).
#   3. O path do projeto gravado no `make install` (caso o binário tenha sido
#      instalado fora do projeto, ex.: ~/.local/bin). O placeholder abaixo é
#      substituído pelo Makefile no momento do install.
coruja_dir() {
  if [[ -n "${CORUJA_DIR:-}" ]]; then
    echo "$CORUJA_DIR"
    return
  fi

  local self="${BASH_SOURCE[0]}"
  while [[ -h "$self" ]]; do self="$(readlink "$self")"; done
  local dir
  dir="$(cd "$(dirname "$self")" >/dev/null 2>&1 && pwd)"

  if [[ -f "$dir/docker-compose.yml" ]]; then
    echo "$dir"
    return
  fi

  echo "__CORUJA_PROJECT_DIR__"
}

# Imprime o backend de compose (uma ou duas palavras). Retorna 1 se nenhum existe.
compose_cmd() {
  if [[ -n "${COMPOSE:-}" ]]; then
    echo "$COMPOSE"
    return 0
  fi
  if docker compose version >/dev/null 2>&1; then
    echo "docker compose"
    return 0
  fi
  if command -v docker-compose >/dev/null 2>&1; then
    echo "docker-compose"
    return 0
  fi
  if command -v podman-compose >/dev/null 2>&1; then
    echo "podman-compose"
    return 0
  fi
  return 1
}

# default_mkcert_caroot — diretório do rootCA do mkcert (TLS local do dev-stack).
# Pergunta ao mkcert quando instalado; senão cai no diretório padrão dele.
default_mkcert_caroot() {
  if command -v mkcert >/dev/null 2>&1; then
    mkcert -CAROOT
    return
  fi
  echo "$HOME/.local/share/mkcert"
}

# Roda o compose a partir do diretório do projeto, repassando os argumentos.
run_compose() {
  local raw
  raw="$(compose_cmd)" || {
    echo "erro: nenhum backend de compose encontrado." >&2
    echo "      instale o docker (compose) ou podman-compose, ou defina COMPOSE=." >&2
    exit 1
  }
  local -a cc
  read -r -a cc <<< "$raw"

  local dir
  dir="$(coruja_dir)"
  if [[ ! -f "$dir/docker-compose.yml" ]]; then
    echo "erro: docker-compose.yml não encontrado em '$dir'." >&2
    echo "      defina CORUJA_DIR apontando para o projeto, ou rode de dentro dele." >&2
    exit 1
  fi
  # pdf-kit monta o rootCA do mkcert via ${MKCERT_CAROOT}. O podman-compose 1.5.0 NÃO
  # parseia default aninhado (${VAR:-${HOME}/x}) — fecha no primeiro `}` e deixa lixo
  # concatenado, quebrando até o `down`. Resolvemos o CAROOT aqui (o shell suporta
  # aninhamento) pra que TODO comando — não só os que passam pelo wizard — tenha a var.
  export MKCERT_CAROOT="${MKCERT_CAROOT:-$(default_mkcert_caroot)}"

  # Override opcional do pdf-kit (consumer local de PDF do LDI). Incluído sempre que o
  # arquivo existe — o serviço só sobe quando entra na lista resolvida (ver resolve.sh).
  local -a files=(-f docker-compose.yml)
  [[ -f "$dir/docker-compose.pdfkit.yaml" ]] && files+=(-f docker-compose.pdfkit.yaml)
  ( cd "$dir" && "${cc[@]}" "${files[@]}" "$@" )
}
