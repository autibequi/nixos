#!/usr/bin/env bash
set -u

WS="${1:-}"
CMD="${2:-}"

if [ -z "$CMD" ]; then
  exit 127
fi

exec hyprctl dispatch exec "[workspace ${WS} silent] uwsm app -- ${CMD}"
