#!/usr/bin/env bash
# Zion: bootstrap do agente no container.
# Delega para o bootstrap do repo NixOS. No container, mounts ficam sob /workspace (nixos, obsidian, logs, mount).

# Repo NixOS em /workspace/nixos. Opcional: symlink /workspace/host -> /workspace/nixos para compatibilidade.
if [[ -d /workspace/nixos ]] && [[ -d /workspace ]] && [[ ! -e /workspace/host ]]; then
  ln -sfn /workspace/nixos /workspace/host 2>/dev/null || true
fi

# Bootstrap completo (dashboard, sync stow, módulos) vive em /workspace/nixos/scripts/bootstrap.sh
if [[ -f /workspace/nixos/scripts/bootstrap.sh ]]; then
  source /workspace/nixos/scripts/bootstrap.sh
  _ret=$?
fi

# Fallback mínimo se o repo não tiver scripts (não deveria acontecer)
if [[ -z "${_ret:-}" ]]; then
  echo "[zion bootstrap] /workspace/nixos/scripts/bootstrap.sh não encontrado; continuando sem dashboard." >&2
  _ret=0
fi

# Última coisa: árvore do primeiro nível da pasta atual
_here="$(pwd)"
echo "[zion bootstrap] Árvore de: ${_here}" >&2
if command -v tree &>/dev/null; then
  tree -L 1 -a --dirsfirst 2>/dev/null || tree -L 1 -a
else
  find . -maxdepth 1 -print 2>/dev/null | sed -e 's;[^/]*/;|____;g;s;____|; |;g' | head -50
fi
return "${_ret}" 2>/dev/null || exit "${_ret}"
