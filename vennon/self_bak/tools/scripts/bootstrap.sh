#!/usr/bin/env bash
# Leech: bootstrap do agente no container.
# Delega para o bootstrap do repo NixOS. No container, mounts ficam sob /workspace (nixos, obsidian, logs, mount).

# Repo NixOS: em /workspace/nixos (scheduler) ou em /workspace/home (--host). Symlink /workspace/host para compatibilidade.
if [[ -d /workspace/nixos ]] && [[ -d /workspace ]] && [[ ! -e /workspace/host ]]; then
  ln -sfn /workspace/nixos /workspace/host 2>/dev/null || true
elif [[ -d /workspace/home ]] && [[ -f /workspace/home/CLAUDE.md ]] && [[ -d /workspace ]] && [[ ! -e /workspace/host ]]; then
  ln -sfn /workspace/home /workspace/host 2>/dev/null || true
fi

# Bootstrap completo (dashboard, sync stow, módulos): nixos ou mnt (host-edit)
for base in /workspace/nixos /workspace/home; do
  if [[ -f "$base/scripts/bootstrap.sh" ]]; then
    source "$base/scripts/bootstrap.sh"
    _ret=$?
    break
  fi
  _ret=
done

if [[ -z "${_ret:-}" ]]; then
  echo "[leech bootstrap] scripts/bootstrap.sh do repo NixOS não encontrado; continuando sem dashboard." >&2
  _ret=0
fi


return "${_ret}" 2>/dev/null || exit "${_ret}"
