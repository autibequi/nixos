# lib/monitor.sh — abre o oxker escopado no projeto coruja.
#
# Compartilhado entre o comando `monitor` (abre direto) e o `launch_stack` em modo
# background (abre na sequência do `up -d`, pra acompanhar o boot dos containers).
#
# Retorna != 0 SEM abrir quando falta pré-requisito (oxker, socket do podman,
# compose, ou TTY). O caller decide se isso é fatal (comando `monitor`) ou só um
# aviso (auto-open pós-launch — o stack já subiu, o monitor é bônus).
#
# Trocado de lazydocker pro oxker (2026-07-01). oxker não tem o conceito de
# "painel Services por compose project" do lazydocker — escopamos via `--filter`
# pelo prefixo comum dos container_name (`estrategia-*`, ver docker-compose.yml).
# ⚠️ Flag `--filter` não confirmada contra a versão instalada — checar `oxker --help`
# na primeira execução e ajustar se o nome/comportamento da flag divergir.
coruja_open_monitor() {
  # oxker é TUI: sem TTY na saída (pipe, CI, nohup) não há o que renderizar.
  if [[ ! -t 1 ]]; then
    echo "monitor: sem TTY na saída — pulando oxker." >&2
    return 1
  fi

  if ! command -v oxker >/dev/null 2>&1; then
    echo "monitor: oxker não encontrado no PATH." >&2
    echo "         instale via gerenciador de pacotes, ou rode: nix-shell -p oxker" >&2
    return 1
  fi

  local dir
  dir="$(coruja_dir)"
  if [[ ! -f "$dir/docker-compose.yml" ]]; then
    echo "monitor: docker-compose.yml não encontrado em '$dir'." >&2
    echo "         defina CORUJA_DIR apontando para o projeto." >&2
    return 1
  fi

  # podman é daemonless: a API compatível com Docker (que o oxker usa) só existe
  # quando o socket rootless do systemd está ativo. Sem ele, o oxker dá
  # "Cannot connect to the Docker daemon".
  if [[ -z "${DOCKER_HOST:-}" ]]; then
    local sock="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock"
    if [[ -S "$sock" ]]; then
      export DOCKER_HOST="unix://$sock"
    else
      echo "monitor: podman socket não está ativo ($sock)." >&2
      echo "         ative uma vez (persistente): systemctl --user enable --now podman.socket" >&2
      return 1
    fi
  fi

  ( cd "$dir" && oxker --filter estrategia )
}
