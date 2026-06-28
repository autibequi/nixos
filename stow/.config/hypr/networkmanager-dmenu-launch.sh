#!/usr/bin/env bash
set -u

PATH="${HOME}/.config/hypr:/run/current-system/sw/bin:${HOME}/.nix-profile/bin:/usr/bin:/bin:${PATH:-}"

systemctl --user start elephant.service walker.service >/dev/null 2>&1 || true

exec networkmanager_dmenu "$@"
