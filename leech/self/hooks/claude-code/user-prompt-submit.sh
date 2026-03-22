#!/usr/bin/env bash
# Hook: UserPromptSubmit — lazy-load de LITE + ENV + OBSIDIAN
#
# Lógica:
#   - Prompt simples (curto, sem keywords de task): adia contexto para próxima mensagem
#   - Prompt complexo (task/código): injeta imediatamente
#   - Segunda mensagem em diante: sempre injeta se ainda não injetou
#   - Headless/Agent/leech_debug: injeta imediatamente, sem lazy
#
# stdout → system-reminder (Claude vê) | /tmp/leech-ctx-loaded = lock de sessão

# ── Load .leech ────────────────────────────────────────────────────────────────
_LEECH_FILE="${HOME:-/home/claude}/.leech"; [ -f "$_LEECH_FILE" ] || _LEECH_FILE="/.leech"
[ -f "$_LEECH_FILE" ] && { set -a; source "$_LEECH_FILE" 2>/dev/null || true; set +a; }

HEADLESS="${HEADLESS:-0}"
LEECH_DEBUG="${LEECH_DEBUG:-OFF}"
AGENT_MODE="0"
{ [ -n "${AGENT_NAME:-}" ] || [ -n "${TASK_NAME:-}" ]; } && AGENT_MODE="1"

CTX_LOCK="/tmp/leech-ctx-loaded"
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
[ -d "/workspace/host" ] && LEECH_EDIT="1" || LEECH_EDIT="${LEECH_EDIT:-0}"

# ── Injeta LITE + ENV + OBSIDIAN ──────────────────────────────────────────────
inject_full_context() {
  # LITE
  if [ "$LEECH_DEBUG" = "OFF" ] && [ "$HEADLESS" != "1" ] && [ "$AGENT_MODE" != "1" ]; then
    LITE_MD="$WS/leech/system/LITE.md"
    [ -f "$LITE_MD" ] || LITE_MD="/workspace/self/system/LITE.md"
    if [ -f "$LITE_MD" ]; then
      echo "---LITE---"
      cat "$LITE_MD"
      echo "---/LITE---"
    fi
  fi

  # ENV
  echo "---ENV---"
  if [ "$IN_DOCKER" = "1" ]; then
    cat <<'DOCKER'
Você está DENTRO de um container Docker (in_docker=1).
NÃO executar: nixos-rebuild, nh os switch, systemctl — não afeta o host.
Para comandos de sistema, pedir ao usuário rodar no host.
Superpoderes: todo Nixpkgs disponível via `nix-shell -p <pkg>`.

Estrutura /workspace:
  /workspace/self/          engine dos agentes (prompts, scripts, skills, personas)
  /workspace/mnt/           ZONA DE TRABALHO — pasta do host attachada (rw)
                            pode ser ~/nixos, ~/projects/ com vários repos, etc.
                            aqui você lê, edita e commita código
  /workspace/obsidian/      CÉREBRO PERSISTENTE entre execuções
                            o usuário acessa no Obsidian — use para notas,
                            kanban, resultados, memória cross-session
  /workspace/logs/          logs attachados pelo usuário
    host/journal/           logs do sistema host (journald)
    docker/monolito/        logs do monolito Go
    docker/bo-container/    logs do BO Container
    docker/front-student/   logs do Front Student
  /workspace/dockerized/    configs docker dos serviços (Dockerfile, compose, .env)
  /workspace/.hive-mind/    área efêmera compartilhada entre containers (locks, sinais)

Se leech_edit=1: lab mode — /workspace/host/ contém o repo NixOS+Leech (editável).
Se leech_edit=0: /workspace/mnt é um projeto externo do usuário.
DOCKER
    if [ "$LEECH_EDIT" = "1" ]; then
      cat <<'LEECH_REPOS'

LAB MODE (leech_edit=1):
  /workspace/mnt  = Projeto do usuário (zona de trabalho normal — igual leech new)
  /workspace/host/ = NixOS+Leech source (~/nixos) — EDITÁVEL para auto-aperfeiçoamento
                    (modules/, configuration.nix, flake.nix, stow/, leech/)
                    Use para melhorar skills, hooks, prompts, agents, CLI do Leech.
                    Mudanças aqui afetam o sistema e as próximas sessões.
  /workspace/self = Bind mount de ~/nixos/self (mesmo conteúdo que /workspace/host/leech)

REGRA: /workspace/host/ é sua zona de evolução. Edite-a quando identificar melhorias
       em skills, agents, hooks ou prompts. Commits vão pro repo NixOS do host.
LEECH_REPOS
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
  echo "REGRA: para interagir com /workspace/obsidian/ carregar skill \`obsidian\`."
  echo "Skill composta — sub-skills em /workspace/self/skills/obsidian/:"
  echo "  board.md      — mapa do vault, tasks, roster, delegacao, quota"
  echo "  agentroom.md  — protocolo agents: scheduling, memory, ciclo"
  echo "  graph.md      — manter grafo Ctrl+G: frontmatter, hubs, wiseman"
  echo "  dataview.md   — queries Dataview/DataviewJS"
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
