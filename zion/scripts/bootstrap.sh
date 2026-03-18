#!/usr/bin/env bash
# Zion: bootstrap do agente no container.
# Delega para o bootstrap do repo NixOS. No container, mounts ficam sob /workspace (nixos, obsidian, logs, mount).

# Repo NixOS: em /workspace/nixos (scheduler) ou em /workspace/mnt (zion host-edit). Symlink /workspace/host para compatibilidade.
if [[ -d /workspace/nixos ]] && [[ -d /workspace ]] && [[ ! -e /workspace/host ]]; then
  ln -sfn /workspace/nixos /workspace/host 2>/dev/null || true
elif [[ -d /workspace/mnt ]] && [[ -f /workspace/mnt/CLAUDE.md ]] && [[ -d /workspace ]] && [[ ! -e /workspace/host ]]; then
  ln -sfn /workspace/mnt /workspace/host 2>/dev/null || true
fi

# Bootstrap completo (dashboard, sync stow, módulos): nixos ou mnt (host-edit)
for base in /workspace/nixos /workspace/mnt; do
  if [[ -f "$base/scripts/bootstrap.sh" ]]; then
    source "$base/scripts/bootstrap.sh"
    _ret=$?
    break
  fi
  _ret=
done

if [[ -z "${_ret:-}" ]]; then
  echo "[zion bootstrap] scripts/bootstrap.sh do repo NixOS não encontrado; continuando sem dashboard." >&2
  _ret=0
fi

# Grafana MCP — registra se credenciais disponíveis e não registrado ainda
if [[ -n "${GRAFANA_URL:-}" ]] && [[ -n "${GRAFANA_TOKEN:-}" ]]; then
  if ! grep -q '"grafana"' ~/.claude/settings.json 2>/dev/null; then
    claude mcp add grafana \
      --transport stdio \
      -- mcp-grafana \
      --grafana-url "$GRAFANA_URL" \
      --grafana-api-key "$GRAFANA_TOKEN" 2>/dev/null || true
  fi
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
