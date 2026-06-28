#!/usr/bin/env bash
set -u

PATH="/run/current-system/sw/bin:${HOME}/.nix-profile/bin:/usr/bin:/bin:${PATH:-}"

if ! systemctl --user --quiet is-active elephant.service; then
  systemctl --user start elephant.service >/dev/null 2>&1 || (elephant >/tmp/elephant.log 2>&1 &)
fi

for _ in {1..20}; do
  systemctl --user --quiet is-active elephant.service && break
  sleep 0.05
done

if ! systemctl --user --quiet is-active walker.service; then
  systemctl --user start walker.service >/dev/null 2>&1 || true
fi

args=("$@")

has_provider=false
has_width=false
has_hideqa=false
has_nosearch=false
has_maxheight=false
has_minheight=false
has_nohints=false
has_height=false
provider=""

for a in "${args[@]}"; do
  case "$a" in
    --provider|--provider=*|-m) has_provider=true ;;
    --width|--width=*|-w) has_width=true ;;
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

if ! $has_provider && ! $has_width; then
  args=(--width 720 "${args[@]}")
fi

case "$provider" in
  menus:wifi|menus:power|menus:screenshot)
    args=(--hideqa "${args[@]}")
    ;;
esac

# menus:power — lista fixa, sem busca, altura proporcional aos itens
if [[ "$provider" == "menus:power" ]]; then
  compact=()
  if ! $has_nosearch; then compact+=(--nosearch); fi
  if ! $has_width; then compact+=(--width 320); fi
  if ! $has_minheight; then compact+=(--minheight 288); fi
  if ! $has_maxheight; then compact+=(--maxheight 288); fi
  args=("${compact[@]}" "${args[@]}")
fi

# menus:screenshot — 4 linhas, sem scroll (altura = 4×44px + padding)
if [[ "$provider" == "menus:screenshot" ]]; then
  compact=()
  if ! $has_nohints; then compact+=(--nohints); fi
  if ! $has_nosearch; then compact+=(--nosearch); fi
  if ! $has_width; then compact+=(--width 280); fi
  if ! $has_height; then compact+=(--height 228); fi
  if ! $has_minheight; then compact+=(--minheight 188); fi
  if ! $has_maxheight; then compact+=(--maxheight 188); fi
  args=("${compact[@]}" "${args[@]}")
fi

# clipboard — lista + preview lado a lado, altura estável
if [[ "$provider" == "clipboard" ]]; then
  compact=()
  if ! $has_width; then compact+=(--width 880); fi
  if ! $has_minheight; then compact+=(--minheight 360); fi
  if ! $has_maxheight; then compact+=(--maxheight 360); fi
  args=("${compact[@]}" "${args[@]}")
fi

exec walker "${args[@]}"
