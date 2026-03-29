#!/usr/bin/env bash
# Hook: UserPromptSubmit — lazy-load de LITE + ENV + OBSIDIAN
#
# Lógica:
#   - Prompt simples (curto, sem keywords de task): adia contexto para próxima mensagem
#   - Prompt complexo (task/código): injeta imediatamente
#   - Segunda mensagem em diante: sempre injeta se ainda não injetou
#   - Headless/Agent/vennon_debug: injeta imediatamente, sem lazy
#
# stdout → system-reminder (Claude vê) | /tmp/vennon-ctx-loaded = lock de sessão

# ── Load .vennon ────────────────────────────────────────────────────────────────
_vennon_FILE="${HOME:-/home/claude}/.vennon"; [ -f "$_vennon_FILE" ] || _vennon_FILE="/.vennon"
[ -f "$_vennon_FILE" ] && { set -a; source "$_vennon_FILE" 2>/dev/null || true; set +a; }

HEADLESS="${HEADLESS:-0}"
vennon_DEBUG="${vennon_DEBUG:-OFF}"
AGENT_MODE="0"
{ [ -n "${AGENT_NAME:-}" ] || [ -n "${TASK_NAME:-}" ]; } && AGENT_MODE="1"

CTX_LOCK="/tmp/vennon-ctx-loaded"
PENDING="${CTX_LOCK}.pending"

# Já injetou nessa sessão → skip
[ -f "$CTX_LOCK" ] && exit 0

# ── Detecta workspace ─────────────────────────────────────────────────────────
if [ -d "/workspace/nixos" ] && [ -f "/workspace/nixos/CLAUDE.md" ]; then
  WS="/workspace/nixos"
elif [ -d "/workspace/host" ] && [ -f "/workspace/host/CLAUDE.md" ]; then
  WS="/workspace/host"
elif [ -d "/workspace" ] && [ -f "/workspace/CLAUDE.md" ]; then
  WS="/workspace"
else
  WS="$(pwd)"
fi
{ [ "${CLAUDE_ENV:-}" = "container" ] || [ -f "/.dockerenv" ]; } && IN_DOCKER="1" || IN_DOCKER="${IN_DOCKER:-0}"
HOST_ATTACHED="${HOST_ATTACHED:-0}"
{ [ "$HOST_ATTACHED" = "1" ] || { [ -d "/workspace/host" ] && [ -w "/workspace/host" ]; }; } && HOST_ATTACHED="1"

# ── Injeta LITE + ENV + OBSIDIAN ──────────────────────────────────────────────
inject_full_context() {
  # ENV
  echo "---ENV---"
  if [ "$IN_DOCKER" = "1" ]; then
    cat <<'DOCKER'
Você está DENTRO de um container Docker (in_docker=1).
NÃO executar: nixos-rebuild, nh os switch, systemctl — não afeta o host.
Para comandos de sistema, pedir ao usuário rodar no host.
Superpoderes: todo Nixpkgs disponível via `nix-shell -p <pkg>`.

Estrutura /workspace — permissões:
  /workspace/self/          SEMPRE rw — engine vennon (skills, hooks, agents, scripts)
  /workspace/obsidian/      SEMPRE rw — vault Obsidian (cérebro compartilhado, todos os agentes)
  /workspace/home/           SEMPRE rw — zona de trabalho (projeto do host)
  /workspace/host/          ro default, rw com --host — repo NixOS (~/nixos)
  /workspace/logs/          logs do host e serviços Docker
  /workspace/dockerized/    configs docker dos serviços (Dockerfile, compose, .env)
  /workspace/.hive-mind/    área efêmera compartilhada entre containers

host_attached=1 (--host ou mount_host=true): /workspace/host/ é rw — editar NixOS+vennon.
host_attached=0: /workspace/host/ existe mas é read-only.
DOCKER
    if [ "$HOST_ATTACHED" = "1" ]; then
      cat <<'vennon_REPOS'

HOST ATTACHED (host_attached=1):
  /workspace/home   = Projeto do usuário (zona de trabalho — igual yaa)
  /workspace/host/ = NixOS+vennon source (~/nixos) — EDITÁVEL
                     modules/, configuration.nix, flake.nix, stow/, vennon/
                     Edite para melhorar skills, hooks, prompts, agents, CLI.
                     Mudanças aqui afetam o sistema e as próximas sessões.
  /workspace/self  = ~/nixos/vennon/self (mesma fonte que /workspace/host/vennon/self)
  /workspace/obsidian = vault Obsidian — sempre editável por qualquer agente

REGRA: /workspace/host/ é sua zona de evolução. Commits vão pro repo NixOS do host.
vennon_REPOS
    fi
    if [ "$HEADLESS" = "1" ]; then
      echo ""
      echo "Modo HEADLESS (headless=1):"
      echo "  autonomia total — não esperar input, não fazer perguntas"
      echo "  maximizar progresso dentro do timeout"
      echo "  ciclos curtos: executar → salvar parcial → continuar"
      echo "  sem output decorativo, foco em execução e persistência"
    fi
  else
    echo "Você está NO HOST, fora do Docker (in_docker=0)."
    echo "  pode executar nixos-rebuild, nh os switch, systemctl normalmente"
    echo "  os paths /workspace/* não existem aqui"
    echo "  WS = raiz do repo NixOS no host"
  fi
  echo "---/ENV---"

  # OBSIDIAN
  echo "---OBSIDIAN---"
  echo "REGRA: regras do vault em \`self/superego/README.md\` (entrypoint) → \`self/superego/\` (detalhe)."
  echo "Obsidian skill (templates, mermaid, graph): \`self/skills/meta/obsidian/SKILL.md\`"
  echo "CLI regras: \`/superego\`"
  echo "---/OBSIDIAN---"

}

# ── Headless/Agent: injetar sempre imediatamente ──────────────────────────────
if [ "$HEADLESS" = "1" ] || [ "$AGENT_MODE" = "1" ]; then
  inject_full_context
  touch "$CTX_LOCK"
  exit 0
fi

# ── Detecta complexidade do prompt ───────────────────────────────────────────
INPUT=$(cat)
PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // ""' 2>/dev/null || echo "")
PLEN=${#PROMPT}

is_simple=0
if [ "$PLEN" -lt 120 ]; then
  if ! printf '%s' "$PROMPT" | grep -qiE \
    'implement|cria|fix|debug|build|run|deploy|refactor|install|configur|edit|write|feature|worktree|commit|push|pull|busca|busque|search|analis|investiga|verific|adiciona|remove|muda|altera|update|hook|script|cod[ie]|função|function|class|erro|error|test|instala|configura|ajusta|converte|implementa|faz|fazer|mostra|roda|execut'; then
    is_simple=1
  fi
fi

# ── Aplica lógica de lazy-load ────────────────────────────────────────────────
if [ -f "$PENDING" ] || [ "$is_simple" = "0" ]; then
  # Complexo agora, OU simples anterior pendente → injeta
  inject_full_context
  touch "$CTX_LOCK"
  rm -f "$PENDING"
else
  # Simples: adia para próxima mensagem
  touch "$PENDING"
fi
