# lib/autodown.sh — auto-down do stack por UPTIME. Após AUTO_DOWN (ex: 1h) o stack
# desce sozinho (defesa contra ficar ligado/travado indefinidamente). Mecanismo: um
# processo em background (sleep TTL; coruja down) com PID em coruja-autodown.pid.
# Cancelado por um `coruja down` manual ou ao reagendar num novo `up`.

# PID file no runtime dir (tmpfs), não no repo: é estado efêmero de UM boot — o processo
# agendado morre no reboot e o tmpfs zera junto, então nunca sobra PID stale nem arquivo
# untracked sujando o git status do projeto.
_autodown_pidfile() { echo "${XDG_RUNTIME_DIR:-/tmp}/coruja-autodown.pid"; }

# Mata um agendamento pendente (o sleep + o down que rodaria). Idempotente.
autodown_cancel() {
  local pf pid
  pf="$(_autodown_pidfile)"
  [[ -f "$pf" ]] || return 0
  pid="$(cat "$pf" 2>/dev/null)"
  if [[ -n "$pid" ]]; then
    pkill -P "$pid" 2>/dev/null || true   # mata o `sleep` filho
    kill "$pid" 2>/dev/null || true       # mata o sh do agendamento
  fi
  rm -f "$pf"
}

# Agenda `coruja down` daqui a TTL (formato do sleep: 1h, 30m, 2h…). 'off' = não agenda.
autodown_schedule() {
  local ttl="${1:-1h}"
  autodown_cancel
  [[ -z "$ttl" || "$ttl" == "off" ]] && return 0
  # setsid desacopla da sessão (sobrevive ao foreground do `up`). `coruja` resolve o dir
  # do projeto sozinho, não depende do cwd.
  setsid sh -c "sleep '$ttl' && coruja down" >/dev/null 2>&1 &
  echo "$!" > "$(_autodown_pidfile)"
  echo "auto-down: 'coruja down' agendado em $ttl  (cancela com 'coruja down' ou 'coruja up --no-auto-down')"
}
