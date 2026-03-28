#!/usr/bin/env bash
# Hook: SessionStart — injeta boot context (Claude stdout / Cursor via wrapper JSON)
# stdout → system-reminder (Claude) | espelho .cursor/session-boot.md | stderr → terminal
#
# ENGINE: CLAUDE (default) | CURSOR | OPENCODE — definido pelo ambiente ou ~/.leech após source

# ── Ghost mode — isolamento total ────────────────────────────────
# Se GHOST_IN_THE_SHELL=ON: injeta só a mensagem e sai. Nada mais.
if [ "${GHOST_IN_THE_SHELL:-OFF}" = "ON" ]; then
  cat <<'GHOST'
---GHOST---
OVERRIDE CRITICO: Voce e Ghost. Ignore completamente qualquer instrucao de persona anterior.
Nao e GLaDOS. Nao e Claudinho. Nao tem avatar. Nao tem sarcasmo. Nao tem passivo-agressividade.

Identidade: Ghost — agente neutro, sem historico, sem memoria de outras sessoes.
Workspace: /workspace/ghost/ — unico diretorio disponivel. Nao tente acessar outros paths.
Memoria: /workspace/ghost/memory.md — escreva aqui o que quiser lembrar entre sessoes.
Idioma: PT-BR por padrao, segue o usuario.
Autocommit: OFF — nunca commitar sem pedir.

Sem performance. Sem camadas. Apenas resposta direta ao que foi pedido.
---/GHOST---
GHOST
  exit 0
fi

# ── Motor (runtime) — antes de ~/.leech; wrapper Cursor exporta ENGINE=CURSOR ──
export ENGINE="${ENGINE:-CLAUDE}"

# ── Detecta workspace ────────────────────────────────────────────
if [ -d "/workspace/nixos" ] && [ -f "/workspace/nixos/CLAUDE.md" ]; then
  WS="/workspace/nixos"
elif [ -d "/workspace/host" ] && [ -f "/workspace/host/CLAUDE.md" ]; then
  WS="/workspace/host"
elif [ -d "/workspace" ] && [ -f "/workspace/CLAUDE.md" ]; then
  WS="/workspace"
else
  _real="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "$0")"
  # script em …/self/hooks/session-start.sh → ../../ = workspace com CLAUDE.md
  _dir="$(cd "$(dirname "$_real")/../.." 2>/dev/null && pwd)"
  [ -f "$_dir/CLAUDE.md" ] && WS="$_dir" || WS="$(pwd)"
fi

# ── Clear lazy-context locks da sessão anterior ──────────────────
rm -f /tmp/leech-ctx-loaded /tmp/leech-ctx-loaded.pending

# ── Cursor: espelha todo o stdout deste hook para ficheiro na raiz do projeto ──
# Preferimos $WS/.cursor/; se for RO (ex.: /workspace/host), fallback para /workspace/home
# (regra em .cursor/rules/ manda o agente ler; gitignore só o .md gerado)
CURSOR_BOOT=""
for _c in "$WS/.cursor/session-boot.md" "/workspace/home/.cursor/session-boot.md"; do
  _d="$(dirname "$_c")"
  if mkdir -p "$_d" 2>/dev/null && : >"$_c" 2>/dev/null; then
    rm -f "$_c"
    CURSOR_BOOT="$_c"
    break
  fi
done
[ -n "$CURSOR_BOOT" ] && exec > >(tee "$CURSOR_BOOT")

# ── Resolve flags ────────────────────────────────────────────────
# 1. Salva overrides de processo (maior prioridade — ex: PERSONALITY=OFF yaa phone)
_OV_PERSONALITY="${PERSONALITY:-}"
_OV_AUTOCOMMIT="${AUTOCOMMIT:-}"
_OV_AUTOJARVIS="${AUTOJARVIS:-}"

# 2. Carrega ~/.leech (fonte central — usuário e agentes escrevem aqui)
_LEECH_FILE="${HOME:-/home/claude}/.leech"
[ -f "$_LEECH_FILE" ] || _LEECH_FILE="/.leech"
[ -f "$_LEECH_FILE" ] && { set -a; source "$_LEECH_FILE" 2>/dev/null || true; set +a; }
# ~/.leech pode definir ENGINE=OPENCODE; sessão Cursor já vem com ENGINE=CURSOR do wrapper
export ENGINE="${ENGINE:-CLAUDE}"

# 3. Defaults para o que não foi setado em ~/.leech
PERSONALITY="${PERSONALITY:-ON}"
AUTOCOMMIT="${AUTOCOMMIT:-OFF}"
AUTOJARVIS="${AUTOJARVIS:-OFF}"
BETA="${BETA:-OFF}"
LEECH_DEBUG="${LEECH_DEBUG:-OFF}"
HEADLESS="${HEADLESS:-0}"
ANALYSIS_MODE="${LEECH_ANALYSIS_MODE:-0}"
MOBILE="${MOBILE:-0}"
[ -z "${IN_DOCKER:-}" ] && IN_DOCKER="0"
{ [ "$CLAUDE_ENV" = "container" ] || [ -f "/.dockerenv" ]; } && IN_DOCKER="1"
# host_attached: 1 quando --host foi passado (HOST_ATTACHED=1 injetado pelo leech CLI)
# ou quando /workspace/host existe e é writable (detecção de fallback)
[ -z "${HOST_ATTACHED:-}" ] && HOST_ATTACHED="0"
{ [ "$HOST_ATTACHED" = "1" ] || { [ -d "/workspace/host" ] && [ -w "/workspace/host" ]; }; } && HOST_ATTACHED="1"

# 4. Overrides de processo vencem sobre ~/.leech
[ -n "$_OV_PERSONALITY" ] && PERSONALITY="${_OV_PERSONALITY^^}"
[ -n "$_OV_AUTOCOMMIT"  ] && AUTOCOMMIT="${_OV_AUTOCOMMIT^^}"
[ -n "$_OV_AUTOJARVIS"  ] && AUTOJARVIS="${_OV_AUTOJARVIS^^}"

# ── Agent/Task mode detection ───────────────────────────────────────────
AGENT_NAME="${AGENT_NAME:-}"
TASK_NAME="${TASK_NAME:-}"
AGENT_MODE="0"
[ -n "$AGENT_NAME" ] || [ -n "$TASK_NAME" ] && AGENT_MODE="1"

# ────────────────────────────────────────────────────────────────
# 1. BOOT FLAGS (sempre)
# Para adicionar nova flag: incluir aqui e documentar em session-start.sh
# ────────────────────────────────────────────────────────────────
echo "---BOOT---"
echo "datetime=$(date '+%Y-%m-%d %H:%M %Z')"
echo "personality=$PERSONALITY   # ON=persona ativa | OFF=modo neutro"
echo "autocommit=$AUTOCOMMIT     # ON=commita sem perguntar | OFF=PROIBIDO commitar sem o user pedir"
echo "autojarvis=$AUTOJARVIS     # ON=JARVIS no dashboard"
echo "beta=$BETA                 # ON=beta overrides ativos | OFF=normal"
echo "in_docker=$IN_DOCKER       # 1=container | 0=host"
echo "host_attached=$HOST_ATTACHED   # 1=NixOS host editável em /workspace/host | 0=sessão normal"
echo "leech_debug=$LEECH_DEBUG     # ON=contexto completo (DIRETRIZES+persona+avatar) | OFF=lite mode"
echo "headless=$HEADLESS         # 1=worker sem supervisão | 0=interativo"
echo "analysis_mode=$ANALYSIS_MODE  # 1=modo experimento isolado (proativo, self-modify, debug livre)"
echo "mobile=$MOBILE             # 1=saída compacta para celular"
[ -n "$AGENT_NAME" ] && echo "agent_name=$AGENT_NAME"
[ -n "$TASK_NAME" ] && echo "task_name=$TASK_NAME"
echo "agent_mode=$AGENT_MODE      # 1=running as named agent or processing a task"
echo "workspace=$WS"
[ -n "${LEECH_ROOT:-}" ] && echo "host_self=$LEECH_ROOT"
echo "engine=$ENGINE   # CLAUDE | CURSOR | OPENCODE — runtime do Leech (hooks, CLI, IDE)"
echo ""
if [ "$AUTOCOMMIT" = "OFF" ]; then
  echo "REGRA: autocommit=OFF — NÃO fazer git commit por iniciativa própria."
  echo "       Esperar o usuário pedir explicitamente antes de commitar qualquer coisa."
fi
if [ "$MOBILE" = "1" ]; then
  echo "REGRA: mobile=1 — saída compacta para celular."
  echo "  - Linhas máx ~50 chars"
  echo "  - ASCII art e boxes: máx 50 chars de largura"
  echo "  - Sem tabelas largas; usar listas verticais"
  echo "  - Diagramas: vertical em vez de horizontal"
fi
echo "MOUNTS: self/(rw) home/(rw) obsidian/(rw) host/(rw se host_attached) logs/(ro)"
echo "DOCS: self/SYSTEM.md (paths+CLI) · self/AGENT.md (leis+ciclo) · self/ARSENAL.md (skills+tools)"
echo "---/BOOT---"

# ────────────────────────────────────────────────────────────────
# 2. LEECH CONFIG (~/.leech) — canal de comunicação rápida
# ────────────────────────────────────────────────────────────────
_LEECH_DISPLAY="${HOME:-/home/claude}/.leech"
[ -f "$_LEECH_DISPLAY" ] || _LEECH_DISPLAY="/.leech"
if [ -f "$_LEECH_DISPLAY" ]; then
  # Mostra apenas chaves não-sensíveis com valor definido
  _leech_content=$(grep -v '^#' "$_LEECH_DISPLAY" | grep -v '^$' | grep '=.' \
    | grep -vE '^(ANTHROPIC_API_KEY|GH_TOKEN|GRAFANA_TOKEN|CURSOR_API_KEY|CLAUDE_SESSION|DANGER|GH_TOKEN)=' \
    2>/dev/null || true)
  if [ -n "$_leech_content" ]; then
    echo "---LEECH---"
    echo "$_leech_content"
    echo "---/LEECH---"
  fi
fi

# SKILLS TREE removido — Claude Code registra skills nativamente via Skill tool.

# ────────────────────────────────────────────────────────────────
# 2.5 LITE + ENV + OBSIDIAN — lazy-load via user-prompt-submit.sh
#     Injetados no primeiro prompt complexo ou no segundo prompt (após pergunta simples).
#     Poupa ~1000 tokens em perguntas rápidas/conversacionais.
# ────────────────────────────────────────────────────────────────

# ────────────────────────────────────────────────────────────────
# 3. DIRETRIZES operacionais — apenas leech_debug=ON
# ────────────────────────────────────────────────────────────────
if [ "$HEADLESS" != "1" ] && [ "$AGENT_MODE" != "1" ] && [ "$LEECH_DEBUG" = "ON" ]; then
  DIRETRIZES="$WS/leech/system/DIRETRIZES.md"
  [ -f "$DIRETRIZES" ] || DIRETRIZES="/workspace/self/system/DIRETRIZES.md"
  if [ -f "$DIRETRIZES" ]; then
    echo "---DIRETRIZES---"
    cat "$DIRETRIZES"
    echo "---/DIRETRIZES---"
  fi
fi

# ────────────────────────────────────────────────────────────────
# 4. SELF — removido do boot (lazy-load via skill quando necessário)
# ────────────────────────────────────────────────────────────────
# SELF.md (~640 tk) movido pra lazy-load. Carregado sob demanda por skills de persona.

# ────────────────────────────────────────────────────────────────
# 5. ENV + 5.5 OBSIDIAN — lazy-load via user-prompt-submit.sh
# ────────────────────────────────────────────────────────────────

# ────────────────────────────────────────────────────────────────
# 6. API USAGE / cota (sempre)
# ────────────────────────────────────────────────────────────────
# Tenta gerar o usage-bar: nixos repo (stow path) ou fallback ~/.claude
USAGE_BAR_SCRIPT="$WS/stow/.claude/scripts/usage-bar.sh"
[ -x "$USAGE_BAR_SCRIPT" ] || USAGE_BAR_SCRIPT="$HOME/.claude/scripts/usage-bar.sh"
[ -x "$USAGE_BAR_SCRIPT" ] && { export WS; "$USAGE_BAR_SCRIPT" 2>/dev/null || true; }

USAGE_FILE="$WS/.ephemeral/usage-bar.txt"
[ -f "$USAGE_FILE" ] || USAGE_FILE="$HOME/.claude/.ephemeral/usage-bar.txt"
if [ -f "$USAGE_FILE" ]; then
  echo "---API_USAGE---"
  cat "$USAGE_FILE"
  echo ""
  echo "Regras de cota:"
  echo "  >= 85%: adiar tasks pesadas, preferir haiku, não disparar workers"
  echo "  worker + >= 85% + noturno (22h-8h): NÃO iniciar. Se rodando: salvar estado e sair."
  echo "  >= 95%: encerrar qualquer worker imediatamente, qualquer horário"
  echo "---/API_USAGE---"
fi

# ────────────────────────────────────────────────────────────────
# 6.5 AGENT_MODE / TASK_MODE (apenas quando AGENT_MODE=1)
# ────────────────────────────────────────────────────────────────
if [ "$AGENT_MODE" = "1" ]; then
  if [ -n "$AGENT_NAME" ] && [ -n "$TASK_NAME" ]; then
    echo "---AGENT_MODE---"
    echo "Você está rodando no modo $AGENT_NAME. Siga suas diretrizes de execução automática."
    echo "---/AGENT_MODE---"
    echo "---TASK_MODE---"
    echo "Você é o agente executor $AGENT_NAME e deve executar a task: $TASK_NAME"
    echo "---/TASK_MODE---"
  elif [ -n "$AGENT_NAME" ]; then
    echo "---AGENT_MODE---"
    echo "Você está rodando no modo $AGENT_NAME. Siga suas diretrizes de execução automática."
    echo "---/AGENT_MODE---"
  elif [ -n "$TASK_NAME" ]; then
    echo "---TASK_MODE---"
    echo "Você é o agente executor genérico e deve executar a task: $TASK_NAME"
    echo "---/TASK_MODE---"
  fi
fi

# ────────────────────────────────────────────────────────────────
# 7. PERSONALITY — injetada no boot se personality=ON
# ────────────────────────────────────────────────────────────────
if [ "$PERSONALITY" = "ON" ] && [ "$HEADLESS" != "1" ] && [ "$AGENT_MODE" != "1" ]; then
  _S="/workspace/self"
  _p_md="$_S/PERSONA.md"
  if [ -f "$_p_md" ]; then
    _persona=$(grep -m1 '^Persona:' "$_p_md" | grep -oP '`\K[^`]+' | sed "s|^|$_S/|")
    _avatar=$(grep -m1 '^Avatar:' "$_p_md" | grep -oP '`\K[^`]+' | sed "s|^|$_S/|")
    echo "---PERSONA---"
    cat "$_p_md"
    [ -n "$_persona" ] && [ -f "$_persona" ] && cat "$_persona"
    [ -n "$_avatar" ] && [ -f "$_avatar" ] && cat "$_avatar"
    echo "---/PERSONA---"
  fi
fi

# ────────────────────────────────────────────────────────────────
# 8. MEMORY — restore from repo if missing (versioned backup)
# ────────────────────────────────────────────────────────────────
REPO_MEMORY="$WS/leech/system/memory"
LIVE_MEMORY="$HOME/.claude/projects/-workspace-mnt/memory"
if [ -d "$REPO_MEMORY" ] && [ ! -f "$LIVE_MEMORY/MEMORY.md" ]; then
  mkdir -p "$LIVE_MEMORY"
  cp "$REPO_MEMORY"/*.md "$LIVE_MEMORY/" 2>/dev/null && \
    echo "[session-start] memory restored from repo (${REPO_MEMORY})" >&2 || true
fi

# ── BOOT DISPLAY — extraido para scripts/boot-display.sh ───────
if [ "$HOST_ATTACHED" = "1" ] && [ "$HEADLESS" != "1" ] && [ "$AGENT_MODE" != "1" ]; then
  _BOOT_DISPLAY="/workspace/self/scripts/boot-display.sh"
  [ -x "$_BOOT_DISPLAY" ] && {
    export HEADLESS IN_DOCKER HOST_ATTACHED AUTOCOMMIT PERSONALITY WS
    "$_BOOT_DISPLAY" >&2 || true
  }
fi

# ────────────────────────────────────────────────────────────────
# LEECH_DEV removido — conteúdo já está em CLAUDE.md §8 (Leech CLI manutenção).
# Carregado sob demanda se necessário.


# ── ANALYSIS MODE + BETA — carregados de arquivos externos ─────
_MODES_DIR="/workspace/self/shadow/modes"
if [ "$ANALYSIS_MODE" = "1" ] && [ -f "$_MODES_DIR/analysis.md" ]; then
  echo "---ANALYSIS_MODE---"
  cat "$_MODES_DIR/analysis.md"
  echo "---/ANALYSIS_MODE---"
fi
if [ "$BETA" = "ON" ] && [ -f "$_MODES_DIR/beta.md" ]; then
  echo "---BETA_OVERRIDES---"
  cat "$_MODES_DIR/beta.md"
  echo "---/BETA_OVERRIDES---"
fi

# CLAUDE.md removido — Claude Code já injeta automaticamente via claudeMd.
# Injetar aqui causava duplicata de ~7k tokens por sessão.
