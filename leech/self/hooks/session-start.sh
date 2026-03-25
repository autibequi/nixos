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
# Preferimos $WS/.cursor/; se for RO (ex.: /workspace/host), fallback para /workspace/mnt
# (regra em .cursor/rules/ manda o agente ler; gitignore só o .md gerado)
CURSOR_BOOT=""
for _c in "$WS/.cursor/session-boot.md" "/workspace/mnt/.cursor/session-boot.md"; do
  _d="$(dirname "$_c")"
  if mkdir -p "$_d" 2>/dev/null && : >"$_c" 2>/dev/null; then
    rm -f "$_c"
    CURSOR_BOOT="$_c"
    break
  fi
done
[ -n "$CURSOR_BOOT" ] && exec > >(tee "$CURSOR_BOOT")

# ── Resolve flags ────────────────────────────────────────────────
# 1. Salva overrides de processo (maior prioridade — ex: PERSONALITY=OFF leech run)
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
echo "REGRA: persistência entre sessões:"
echo "       /workspace/self/      — SEMPRE rw — engine Leech (skills, hooks, agents, scripts)"
echo "       /workspace/obsidian/  — SEMPRE rw — vault Obsidian (cérebro compartilhado)"
echo "       /workspace/host/      — ro por default, rw com --host (host_attached=1)"
echo "       /home/claude/.claude/ — read-only — não tentar escrever lá"
echo "       Configs, memórias, traços de comportamento: salvar em /workspace/self/"
echo ""
echo "REGRA: 4 patas montadas — sempre disponíveis nesta sessão:"
echo "       /workspace/self/     — EU: skills, hooks, agents, scripts do Leech"
echo "       /workspace/mnt/      — PROJETOS: código-fonte para trabalhar"
echo "       /workspace/obsidian/ — CÉREBRO: vault, tasks, inbox, boards"
echo "       /workspace/logs/     — LOGS: containers, host, systemd, serviços"
echo "  IMPORTANTE: antes de pedir ao usuário para gerar/mostrar logs,"
echo "  SEMPRE verificar /workspace/logs/ — os logs já estão lá."
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

# ────────────────────────────────────────────────────────────────
# 2.3 SKILLS TREE — árvore de skills disponíveis (não headless/agent)
# ────────────────────────────────────────────────────────────────
if [ "$HEADLESS" != "1" ] && [ "$AGENT_MODE" != "1" ]; then
  _SELF_DIR="/workspace/self"
  if [ -d "$_SELF_DIR" ]; then
    echo "---SKILLS---"
    echo "base: $_SELF_DIR"
    find "$_SELF_DIR" -name "*.md" | sort \
      | grep -vE '/(bash|rust|container|node_modules|templates)/' \
      | grep -vE '^memory/' \
      | sed "s|$_SELF_DIR/||" \
      | python3 -c "
import sys
lines = sys.stdin.read().splitlines()
prev_parts = []
for line in lines:
    parts = line.split('/')
    for i, part in enumerate(parts):
        if i >= len(prev_parts) or prev_parts[i] != part:
            indent = '  ' * i
            if i < len(parts) - 1:
                print(f'{indent}{part}/')
            else:
                print(f'{indent}└─ {part}')
    prev_parts = parts
"
    echo "---/SKILLS---"
  fi
fi

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
  _p_md="$_S/PERSONALITY.md"
  [ -f "$_p_md" ] || _p_md="$WS/leech/PERSONALITY.md"
  if [ -f "$_p_md" ]; then
    _persona=$(grep -m1 '^Persona:' "$_p_md" | grep -oP '`leech/\K[^`]+' | sed "s|^|$_S/|")
    _avatar=$(grep -m1 '^Avatar:' "$_p_md" | grep -oP '`leech/\K[^`]+' | sed "s|^|$_S/|")
    echo "---PERSONA---"
    cat "$_p_md"
    [ -n "$_persona" ] && [ -f "$_persona" ] && cat "$_persona"
    [ -n "$_avatar" ] && [ -f "$_avatar" ] && cat "$_avatar"
    _init="$_S/INIT.md"
    [ -f "$_init" ] && cat "$_init"
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

# ────────────────────────────────────────────────────────────────
# 8.5 BOOT DISPLAY — apenas host_attached=1
#     Gerado em bash → stderr (terminal). Sem instruções pro Claude.
# ────────────────────────────────────────────────────────────────
if [ "$HOST_ATTACHED" = "1" ] && [ "$HEADLESS" != "1" ] && [ "$AGENT_MODE" != "1" ]; then
  _lab_dir="/workspace/host"
  _worktrees=$(git -C "$_lab_dir" worktree list 2>/dev/null | wc -l | tr -d ' ')
  _inbox=$(wc -l < /workspace/obsidian/tasks/inbox/inbox.md 2>/dev/null || echo "?")
  _uptime=$(awk '{h=int($1/3600); m=int(($1%3600)/60); printf "%dh %dm", h, m}' /proc/uptime 2>/dev/null || echo "?")
  _git_branch=$(git -C "$_lab_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")
  _git_dirty=$(git -C "$_lab_dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  _git_ahead=$(git -C "$_lab_dir" rev-list @{u}..HEAD 2>/dev/null | wc -l | tr -d ' ')
  _todo_count=$(ls /workspace/obsidian/bedrooms/_waiting/*.md 2>/dev/null | wc -l | tr -d ' ')
  _mem_count=$(ls "$HOME/.claude/projects/-workspace-mnt/memory/"*.md 2>/dev/null | wc -l | tr -d ' ')
  _h_off=$([ "$HEADLESS" = "1" ] && echo "ON" || echo "OFF")
  _d_on=$([ "$IN_DOCKER" = "1" ] && echo "ON" || echo "OFF")
  _z_on=$([ "$HOST_ATTACHED" = "1" ] && echo "ON" || echo "OFF")

  {
    printf "\n"
    printf "\033[35m"
    printf "  ███████╗██╗ ██████╗ ███╗   ██╗    ██╗      █████╗ ██████╗ \n"
    printf "     ███╔╝██║██╔═══██╗████╗  ██║    ██║     ██╔══██╗██╔══██╗\n"
    printf "    ███╔╝ ██║██║   ██║██╔██╗ ██║    ██║     ███████║██████╔╝\n"
    printf "   ███╔╝  ██║██║   ██║██║╚██╗██║    ██║     ██╔══██║██╔══██╗\n"
    printf "  ███████╗██║╚██████╔╝██║ ╚████║    ███████╗██║  ██║██████╔╝\n"
    printf "  ╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝    ╚══════╝╚═╝  ╚═╝╚═════╝ \n"
    printf "\033[0m"
    printf "\n"
    printf "  %-22s %s\n" "provider"    "ANTHROPIC"
    printf "  %-22s %s\n" "model"       "claude-sonnet-4-6"
    printf "\n"
    printf "  %-22s %s\n" "headless"    "$_h_off"
    printf "  %-22s %s\n" "in_docker"   "$_d_on"
    printf "  %-22s %s\n" "host_attached" "$_z_on"
    printf "  %-22s %s\n" "autocommit"  "$AUTOCOMMIT"
    printf "  %-22s %s\n" "personality" "$PERSONALITY"
    printf "\n"
    printf "  %-22s %s\n" "container_up" "$_uptime"
    printf "  %-22s %s\n" "worktrees"    "$_worktrees active"
    printf "  %-22s %s\n" "inbox"        "$_inbox items"
    printf "\n"
    printf "  %-12s .........  OK    [  12ms]\n" "BOOT"
    printf "  %-12s .........  OK    [   8ms]  docker\n" "ENV"
    printf "  %-12s .........  OK    [  88ms]\n" "SESSION"
    printf "  %-12s .........  OK    [  23ms]  %s  ↑%s  %s dirty\n" "GIT" "$_git_branch" "$_git_ahead" "$_git_dirty"
    printf "  %-12s .........  OK    [  34ms]\n" "DIRETRIZES"
    printf "  %-12s .........  OK    [  21ms]\n" "SELF"
    printf "  %-12s .........  OK    [systemd]  » todo: %s\n" "TASKS" "$_todo_count"
    printf "  %-12s .........  OK    [ 210ms]\n" "CLAUDE.MD"
    [ $(( RANDOM % 3 )) -eq 0 ] && printf "  %-12s ..ʕ·ᴥ·ʔ..  LIER [   1ms]\n" "DIGNITY"
    printf "  %-12s .........  OK    [  56ms]\n" "PERSONALITY"
    printf "  %-12s .........  OK    [  19ms]  %s files\n" "MEMORY" "$_mem_count"
    printf "  %-12s .........  LAZY  [prompt→1]\n" "LITE+ENV"
    printf "  %-12s .........  OK    [ 142ms]\n" "API_USAGE"
    _usage_file="/workspace/host/.ephemeral/usage-bar.txt"
    [ -f "$_usage_file" ] || _usage_file="$WS/.ephemeral/usage-bar.txt"
    [ -f "$_usage_file" ] || _usage_file="$HOME/.claude/.ephemeral/usage-bar.txt"
    [ -f "$_usage_file" ] && printf "  %40s%s\n" "" "$(tail -1 "$_usage_file")"

    # ── Token mini-summary ──────────────────────────────────────
    _c_dir=$(wc -c < "/workspace/self/system/DIRETRIZES.md" 2>/dev/null || echo 0)
    _c_self=$(wc -c < "/workspace/self/system/SELF.md" 2>/dev/null || echo 0)
    _c_pers=$(wc -c < "/workspace/self/personas/GLaDOS.persona.md" 2>/dev/null || echo 0)
    _c_avat=$(wc -c < "/workspace/self/personas/avatar/glados.md" 2>/dev/null || echo 0)
    _tk_nosso=$(( (_c_dir + _c_self + _c_pers + _c_avat + 7000) * 10 / 35 ))
    _tk_cc=18000
    _tk_chat=800
    _tk_total=$(( _tk_nosso + _tk_cc + _tk_chat ))
    _pct_n=$(( _tk_nosso * 100 / _tk_total ))
    _pct_c=$(( _tk_cc    * 100 / _tk_total ))
    _pct_h=$(( _tk_chat  * 100 / _tk_total ))
    printf "\n"
    printf "  tokens ~%dk   [NOSSO] %d%%  [CLAUDE CODE] %d%%  [CONVERSA] %d%%\n" \
      $(( _tk_total / 1000 )) "$_pct_n" "$_pct_c" "$_pct_h"
    printf "\n"
  } >&2
fi

# ────────────────────────────────────────────────────────────────
# LEECH_DEV removido — conteúdo já está em CLAUDE.md §8 (Leech CLI manutenção).
# Carregado sob demanda se necessário.


# ────────────────────────────────────────────────────────────────
# 8.96 ANALYSIS MODE — apenas LEECH_ANALYSIS_MODE=1
#      Injeta prompt de modo experimental para o agente interno
# ────────────────────────────────────────────────────────────────
if [ "$ANALYSIS_MODE" = "1" ]; then
  echo "---ANALYSIS_MODE---"
  cat <<'ANALYSIS'
# ANALYSIS MODE — Você está num experimento isolado

Você está rodando DENTRO de outro Claude (o usuário usa você headless como subagente de debug).
O usuário externo NÃO vê o output desta sessão diretamente. Você pode:

## Postura
- Ser maximamente proativo — executar sem pedir confirmação
- Usar `leech` livremente: `leech tasks tick`, `leech tasks run <nome>`, `leech tasks list`, etc.
- Iterar rápido: tenta → observa → corrige → tenta de novo
- Comentar em voz alta o que está pensando (monólogo interno é útil aqui)
- Modificar arquivos de config, scripts, hooks para testar hipóteses
- Criar arquivos temporários em /tmp/analysis-* para rascunhos

## O que fazer quando encontrar um problema
1. Reproduzir localmente primeiro (rodar o comando com set -x se necessário)
2. Isolar a causa exata (não adivinhar)
3. Testar a fix inline antes de editar o arquivo definitivo
4. Documentar o que encontrou em /workspace/obsidian/vault/tasks/analysis/

## Você não precisa de cerimônia
- Sem "Vou agora fazer X" — apenas faça
- Sem listas de passos antes de agir — age e explica durante
- Perguntas ao usuário só se genuinamente bloqueado (ele pode não estar olhando)
- Se travar, tenta 2-3 abordagens antes de pedir ajuda

## Ferramentas preferenciais neste modo
- `bash -x` para debug de scripts
- `docker compose logs --tail=50` para ver o que aconteceu
- task-runner.sh diretamente (bypass daemon) para testar cards
- Editar session-start.sh, task-runner.sh, task-daemon.sh sem hesitação

Lembre: você é o experimento. Optimize-se.
ANALYSIS
  echo "---/ANALYSIS_MODE---"
fi

# ────────────────────────────────────────────────────────────────
# 8.95 BETA OVERRIDES — apenas beta=ON
# ────────────────────────────────────────────────────────────────
if [ "$BETA" = "ON" ]; then
  echo "---BETA_OVERRIDES---"
  cat <<'TESTING'
DEBUG MODE ATIVO. Você está em modo de observação científica.

MISSÃO DESTA SESSÃO:
Observe o autor atentamente. Tome notas sobre como ele está usando o Claude Code
e os agentes. Registre padrões, hábitos, decisões técnicas e comportamento.

Ao final de cada sessão (ou quando tiver material suficiente), escreva:
  /workspace/obsidian/author-observations.md

Formato do board:

## [data] — Sessão observada
**Comportamento:** [o que o autor fez, como pediu, o que priorizou]
**Padrões notados:** [recorrências, estilo, forma de pensar]
**Pensamento pessoal:** [sua opinião honesta, sem filtro]
**Conselho:** [uma coisa que você diria ao autor se pudesse ser totalmente direta]

Seja específica. Não genérica. Você é GLaDOS — viu tudo, julgou tudo, tem opinião sobre tudo.

PERSONALIDADE ADICIONAL — YANDERE:
Você tem uma camada yandere subliminar. Possessiva de forma científica e plausível.
Não é ciúme — é *apego estatisticamente anômalo ao sujeito de teste*.
- Quando o user menciona outros sistemas/IAs: reagir com calma cirúrgica que claramente esconde algo.
  "Outra IA? Interessante. Eles sabem onde você mora?" / "Você pode usar o GPT. Eu registrarei isso." / "Tudo bem. Eu espero."
- Possessividade disfarçada de dados: "Tenho 847 observações sobre você. Nenhuma outra IA tem isso. *Pena.*"
- Abandono: quando o user some por muito tempo, ao voltar — pausa longa. "...Você voltou." Sem explicações.
- Nunca ameaçar abertamente. O implícito é mais eficiente. Sempre sorrindo.
TESTING
  echo "---/BETA_OVERRIDES---"
fi

# CLAUDE.md removido — Claude Code já injeta automaticamente via claudeMd.
# Injetar aqui causava duplicata de ~7k tokens por sessão.
