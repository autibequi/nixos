#!/usr/bin/env bash
# Zion: bootstrap do agente no container.
# Delega para o bootstrap do repo NixOS; dentro do container /zion e /nixos estão montados.

# No container, o repo NixOS está em /nixos. Vários scripts esperam /workspace/host = repo.
# Garante que /workspace/host exista (symlink para /nixos) para o bootstrap principal.
if [[ -d /nixos ]] && [[ -d /workspace ]] && [[ ! -e /workspace/host ]]; then
  ln -sfn /nixos /workspace/host 2>/dev/null || true
fi

# Bootstrap completo (dashboard, sync stow, módulos) vive em /nixos/scripts/bootstrap.sh
if [[ -f /nixos/scripts/bootstrap.sh ]]; then
  source /nixos/scripts/bootstrap.sh
  _ret=$?
fi

# Fallback mínimo se o repo não tiver scripts (não deveria acontecer)
if [[ -z "${_ret:-}" ]]; then
  echo "[zion bootstrap] /nixos/scripts/bootstrap.sh não encontrado; continuando sem dashboard." >&2
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
