#!/usr/bin/env bash
# host-perf — logger de performance do host (pega trava/lentidão intermitente).
#   host-perf start    → inicia o sampler em background (RODAR NO HOST)
#   host-perf stop     → para o sampler
#   host-perf status   → sampler rodando? há quanto tempo?
#   host-perf          → (default) LÊ o log: últimos samples + picos (roda em qualquer lugar)
#
# O log vive em <repo>/.ephemeral/perf.log — no host é ~/nixos/.ephemeral/,
# que é o mesmo arquivo montado em /workspace/host/.ephemeral/ no container.
# Por isso: o sampler roda no HOST (vê o host real); o `! host-perf` no container só LÊ.
set -u
ROOT="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")/../.." 2>/dev/null && pwd)"
LOG="$ROOT/.ephemeral/perf.log"
PIDF="/tmp/host-perf.pid"
INTERVAL=5
MAX_LINES=20000   # rotaciona: corta o log se passar disso

_sample() {
  mkdir -p "$(dirname "$LOG")" 2>/dev/null
  while :; do
    ts=$(date '+%Y-%m-%dT%H:%M:%S')
    cpu=$(awk '/^some/{for(i=1;i<=NF;i++)if($i~/^avg10=/){sub("avg10=","",$i);print $i}}' /proc/pressure/cpu 2>/dev/null)
    mem=$(awk '/^some/{for(i=1;i<=NF;i++)if($i~/^avg10=/){sub("avg10=","",$i);print $i}}' /proc/pressure/memory 2>/dev/null)
    io=$(awk  '/^some/{for(i=1;i<=NF;i++)if($i~/^avg10=/){sub("avg10=","",$i);print $i}}' /proc/pressure/io 2>/dev/null)
    load=$(awk '{print $1}' /proc/loadavg 2>/dev/null)
    top=$(ps -eo pcpu,comm --sort=-pcpu 2>/dev/null | awk 'NR>1 && $2!="ps"{printf "%s:%s%%",$2,$1; exit}')
    printf '%s cpu=%s mem=%s io=%s load=%s top=%s\n' "$ts" "${cpu:-?}" "${mem:-?}" "${io:-?}" "${load:-?}" "${top:-?}" >> "$LOG"
    # rotação barata
    n=$(wc -l < "$LOG" 2>/dev/null || echo 0)
    [ "${n:-0}" -gt "$MAX_LINES" ] && tail -n $((MAX_LINES/2)) "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
    sleep "$INTERVAL"
  done
}

case "${1:-read}" in
  start)
    [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF")" 2>/dev/null && { echo "já rodando (pid $(cat "$PIDF"))"; exit 0; }
    setsid bash "$0" __loop >/dev/null 2>&1 &
    echo $! > "$PIDF"
    echo "host-perf logger ON (a cada ${INTERVAL}s → $LOG)"
    ;;
  __loop) _sample ;;
  stop)
    [ -f "$PIDF" ] && kill "$(cat "$PIDF")" 2>/dev/null; pkill -f "$0 __loop" 2>/dev/null
    rm -f "$PIDF"; echo "host-perf logger OFF"
    ;;
  status)
    if [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF")" 2>/dev/null; then
      echo "ON (pid $(cat "$PIDF")) · $(wc -l < "$LOG" 2>/dev/null || echo 0) samples"
    else echo "OFF"; fi
    ;;
  read|*)
    [ -f "$LOG" ] || { echo "sem log ainda. inicie no host: host-perf start"; exit 0; }
    echo "== host-perf · últimos 12 samples =="
    tail -12 "$LOG"
    echo
    echo "== PICOS de pressão (top 8 por cpu/mem/io avg10) =="
    awk '{cpu=$2;gsub("cpu=","",cpu); mem=$3;gsub("mem=","",mem); io=$4;gsub("io=","",io);
          m=cpu; if(mem+0>m)m=mem; if(io+0>m)m=io; print m"\t"$0}' "$LOG" 2>/dev/null \
      | sort -rn | head -8 | cut -f2-
    ;;
esac
