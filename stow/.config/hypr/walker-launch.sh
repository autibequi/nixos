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
for ((i = 0; i < ${#args[@]}; i++)); do
  case "${args[i]}" in
    --provider)
      [[ "${args[i + 1]:-}" == "menus:wifi" ]] && args=(--hideqa "${args[@]}")
      break
      ;;
    --provider=*)
      [[ "${args[i]#--provider=}" == "menus:wifi" ]] && args=(--hideqa "${args[@]}")
      break
      ;;
    -m)
      [[ "${args[i + 1]:-}" == "menus:wifi" ]] && args=(--hideqa "${args[@]}")
      break
      ;;
  esac
done

exec walker "${args[@]}"
