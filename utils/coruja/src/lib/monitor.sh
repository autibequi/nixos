# lib/monitor.sh — abre o lazydocker escopado no projeto coruja.
#
# Compartilhado entre o comando `monitor` (abre direto) e o `launch_stack` em modo
# background (abre na sequência do `up -d`, pra acompanhar o boot dos containers).
#
# Retorna != 0 SEM abrir quando falta pré-requisito (lazydocker, socket do podman,
# compose, ou TTY). O caller decide se isso é fatal (comando `monitor`) ou só um
# aviso (auto-open pós-launch — o stack já subiu, o monitor é bônus).
#
# O painel "Services" do lazydocker mostra só os serviços deste docker-compose
# (logs/stats/restart por serviço). O painel "Containers" lista TODOS os containers
# do host e não é filtrável (lazydocker issue #612) — navegue pelo Services.
coruja_open_monitor() {
  # lazydocker é TUI: sem TTY na saída (pipe, CI, nohup) não há o que renderizar.
  if [[ ! -t 1 ]]; then
    echo "monitor: sem TTY na saída — pulando lazydocker." >&2
    return 1
  fi

  if ! command -v lazydocker >/dev/null 2>&1; then
    echo "monitor: lazydocker não encontrado no PATH." >&2
    echo "         instale via gerenciador de pacotes, ou rode: nix-shell -p lazydocker" >&2
    return 1
  fi

  local dir
  dir="$(coruja_dir)"
  if [[ ! -f "$dir/docker-compose.yml" ]]; then
    echo "monitor: docker-compose.yml não encontrado em '$dir'." >&2
    echo "         defina CORUJA_DIR apontando para o projeto." >&2
    return 1
  fi

  # podman é daemonless: a API compatível com Docker (que o lazydocker usa) só existe
  # quando o socket rootless do systemd está ativo. Sem ele, o lazydocker dá
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

  # COMPOSE_PROJECT_NAME escopa o painel Services no projeto 'estrategia'. Forçado (não
  # herdado do ambiente) porque esta CLI é específica do stack estrategia — casa com o
  # top-level `name: estrategia` do docker-compose.yml. Sob podman, sem esse escopo o
  # lazydocker não linka os containers às definições do compose (issue #676).
  ( cd "$dir" && COMPOSE_PROJECT_NAME=estrategia lazydocker )
}
