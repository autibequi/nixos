#!/usr/bin/env bash
set -u

PATH="/run/current-system/sw/bin:${HOME}/.nix-profile/bin:/usr/bin:/bin:${PATH:-}"

if ! systemctl --user --quiet is-active elephant.service; then
  systemctl --user start elephant.service >/dev/null 2>&1 &
  for _ in {1..8}; do
    systemctl --user --quiet is-active elephant.service && break
    sleep 0.02
  done
fi

if ! systemctl --user --quiet is-active walker.service; then
  systemctl --user start walker.service >/dev/null 2>&1 &
fi

args=("$@")

has_provider=false
has_width=false
has_minwidth=false
has_maxwidth=false
has_hideqa=false
has_nosearch=false
has_maxheight=false
has_minheight=false
has_nohints=false
has_height=false
provider=""

WALKER_W=720
WALKER_H=520

for a in "${args[@]}"; do
  case "$a" in
    --provider|--provider=*|-m) has_provider=true ;;
    --width|--width=*|-w) has_width=true ;;
    --minwidth|--minwidth=*) has_minwidth=true ;;
    --maxwidth|--maxwidth=*) has_maxwidth=true ;;
    --hideqa|-H) has_hideqa=true ;;
    --nosearch|-n) has_nosearch=true ;;
    --nohints|-N) has_nohints=true ;;
    --maxheight|--maxheight=*) has_maxheight=true ;;
    --minheight|--minheight=*) has_minheight=true ;;
    --height|--height=*) has_height=true ;;
  esac
done

for ((i = 0; i < ${#args[@]}; i++)); do
  case "${args[i]}" in
    --provider)
      provider="${args[i + 1]:-}"
      break
      ;;
    --provider=*)
      provider="${args[i]#--provider=}"
      break
      ;;
    -m)
      provider="${args[i + 1]:-}"
      break
      ;;
  esac
done

if ! $has_hideqa; then
  args=(--hideqa "${args[@]}")
fi

if ! $has_provider; then
  # Landing (menus:home): tamanho fixo, não cresce nem encolhe.
  # Ao digitar (busca de apps) a janela mantém a mesma caixa e a lista rola dentro.
  compact=()
  if ! $has_width; then compact+=(--width "$WALKER_W"); fi
  if ! $has_minwidth; then compact+=(--minwidth "$WALKER_W"); fi
  if ! $has_maxwidth; then compact+=(--maxwidth "$WALKER_W"); fi
  if ! $has_height; then compact+=(--height "$WALKER_H"); fi
  if ! $has_minheight; then compact+=(--minheight "$WALKER_H"); fi
  if ! $has_maxheight; then compact+=(--maxheight "$WALKER_H"); fi
  args=("${compact[@]}" "${args[@]}")
fi

case "$provider" in
  menus:wifi|menus:power|menus:screenshot|menus:clock|menus:todoist|menus:shortcuts)
    args=(--hideqa "${args[@]}")
    ;;
esac

# menus:todoist — lista de tarefas com criação via query
if [[ "$provider" == "menus:todoist" ]]; then
  compact=()
  if ! $has_width; then compact+=(--width 640); fi
  if ! $has_minheight; then compact+=(--minheight 300); fi
  if ! $has_maxheight; then compact+=(--maxheight 480); fi
  args=("${compact[@]}" "${args[@]}")
fi

# menus:shortcuts — cheatsheet: lista longa, só largura fixa (flags de altura
# colapsavam a janela no wifi — gtk_scrolled_window assertion; mesma lição)
if [[ "$provider" == "menus:shortcuts" ]]; then
  compact=()
  if ! $has_width; then compact+=(--width 900); fi
  args=("${compact[@]}" "${args[@]}")
fi

# menus:power — 6 linhas, fit-to-content (vertical + horizontal)
if [[ "$provider" == "menus:power" ]]; then
  compact=()
  if ! $has_nosearch; then compact+=(--nosearch); fi
  if ! $has_nohints; then compact+=(--nohints); fi
  power_rows=6
  power_row_h=44
  power_chrome=52
  power_h=$((power_rows * power_row_h + power_chrome))
  # largura ≈ ícone + labels mais longos (power.lua) + padding
  power_longest_label="Hibernate"
  power_longest_sub="uwsm stop"
  power_icon_w=28
  power_icon_gap=12
  power_text_px=8
  power_sub_px=7
  power_label_gap=12
  power_item_pad_x=20
  power_wrapper_pad_x=32
  power_inner_w=$((power_icon_w + power_icon_gap \
    + ${#power_longest_label} * power_text_px \
    + power_label_gap \
    + ${#power_longest_sub} * power_sub_px \
    + power_item_pad_x))
  power_w=$((power_inner_w + power_wrapper_pad_x))
  if ! $has_width; then compact+=(--width "$power_w"); fi
  if ! $has_minwidth; then compact+=(--minwidth "$power_w"); fi
  if ! $has_maxwidth; then compact+=(--maxwidth "$power_w"); fi
  if ! $has_height; then compact+=(--height "$power_h"); fi
  if ! $has_minheight; then compact+=(--minheight "$power_h"); fi
  if ! $has_maxheight; then compact+=(--maxheight "$power_h"); fi
  args=("${compact[@]}" "${args[@]}")
fi

# menus:clock — ações rápidas, sem busca (leve como power)
if [[ "$provider" == "menus:clock" ]]; then
  compact=()
  if ! $has_nosearch; then compact+=(--nosearch); fi
  if ! $has_nohints; then compact+=(--nohints); fi
  if ! $has_width; then compact+=(--width 320); fi
  if ! $has_minheight; then compact+=(--minheight 220); fi
  if ! $has_maxheight; then compact+=(--maxheight 220); fi
  args=("${compact[@]}" "${args[@]}")
fi

# menus:screenshot — 4 linhas, fit-to-content
if [[ "$provider" == "menus:screenshot" ]]; then
  compact=()
  if ! $has_nohints; then compact+=(--nohints); fi
  if ! $has_nosearch; then compact+=(--nosearch); fi
  if ! $has_width; then compact+=(--width 280); fi
  shot_rows=4
  shot_row_h=44
  shot_chrome=52
  shot_h=$((shot_rows * shot_row_h + shot_chrome))
  if ! $has_height; then compact+=(--height "$shot_h"); fi
  if ! $has_minheight; then compact+=(--minheight "$shot_h"); fi
  if ! $has_maxheight; then compact+=(--maxheight "$shot_h"); fi
  args=("${compact[@]}" "${args[@]}")
fi

# menus:wifi — lista de redes. Sem nenhuma flag de tamanho (igual bluetooth,
# que renderiza bem) — flags de altura/nosearch/nohints estavam colapsando
# a janela (gtk_scrolled_window assertion). Ver friction log se voltar a mexer aqui.
if [[ "$provider" == "menus:wifi" ]]; then
  compact=()
  if ! $has_width; then compact+=(--width 480); fi
  args=("${compact[@]}" "${args[@]}")
fi

# clipboard — lista + preview lado a lado, altura estável, largura fixa
if [[ "$provider" == "clipboard" ]]; then
  compact=()
  if ! $has_width; then compact+=(--width 880); fi
  if ! $has_minwidth; then compact+=(--minwidth 880); fi
  if ! $has_maxwidth; then compact+=(--maxwidth 880); fi
  if ! $has_minheight; then compact+=(--minheight 360); fi
  if ! $has_maxheight; then compact+=(--maxheight 360); fi
  args=("${compact[@]}" "${args[@]}")
fi

exec walker "${args[@]}"
