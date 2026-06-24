# monitor — abre o lazydocker escopado no projeto coruja.
#
# Lógica em lib/monitor.sh (coruja_open_monitor), compartilhada com o auto-open do
# `launch_stack` em background. Aqui a falta de pré-requisito é fatal (exit 1).

coruja_open_monitor || exit 1
