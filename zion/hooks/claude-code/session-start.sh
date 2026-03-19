#!/usr/bin/env bash
# Hook: SessionStart — injeta boot context pro Claude via stdout
# stdout → system-reminder (Claude vê) | stderr → terminal do user (dashboard visual)

# ── Detecta workspace ────────────────────────────────────────────
if [ -d "/workspace/nixos" ] && [ -f "/workspace/nixos/CLAUDE.md" ]; then
  WS="/workspace/nixos"
elif [ -d "/workspace/host" ] && [ -f "/workspace/host/CLAUDE.md" ]; then
  WS="/workspace/host"
elif [ -d "/workspace" ] && [ -f "/workspace/CLAUDE.md" ]; then
  WS="/workspace"
else
  _real="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "$0")"
  _dir="$(cd "$(dirname "$_real")/../../../.." 2>/dev/null && pwd)"
  [ -f "$_dir/CLAUDE.md" ] && WS="$_dir" || WS="$(pwd)"
fi

# ── Dashboard visual pro user (stderr) ──────────────────────────
BOOTSTRAP_SH="$WS/scripts/bootstrap.sh"
[ -x "$BOOTSTRAP_SH" ] && "$BOOTSTRAP_SH" >&2

# ── Resolve flags ────────────────────────────────────────────────
PERSONALITY="ON"; [ -f "$WS/.ephemeral/personality-off" ] && PERSONALITY="OFF"
AUTOCOMMIT="OFF"; [ -f "$WS/.ephemeral/auto-commit" ]    && AUTOCOMMIT="ON"
AUTOJARVIS="OFF"; [ -f "$WS/.ephemeral/auto-jarvis" ]    && AUTOJARVIS="ON"
HEADLESS="${HEADLESS:-0}"
PUPPY_TIMEOUT="${PUPPY_TIMEOUT:-}"
IN_DOCKER="0"
{ [ "$CLAUDE_ENV" = "container" ] || [ -f "/.dockerenv" ]; } && IN_DOCKER="1"
ZION_EDIT="0"
[ -d "/workspace/logs" ] && ZION_EDIT="1"

# ── Agent/Task mode detection ───────────────────────────────────────────
AGENT_NAME="${AGENT_NAME:-}"
TASK_NAME="${TASK_NAME:-}"
AGENT_MODE="0"
[ -n "$AGENT_NAME" ] || [ -n "$TASK_NAME" ] && AGENT_MODE="1"

# ────────────────────────────────────────────────────────────────
# 1. BOOT FLAGS (sempre)
# Para adicionar nova flag: incluir aqui e documentar em bootstrap.md
# ────────────────────────────────────────────────────────────────
echo "---BOOT---"
echo "datetime=$(date '+%Y-%m-%d %H:%M %Z')"
echo "personality=$PERSONALITY   # ON=persona ativa | OFF=modo neutro"
echo "autocommit=$AUTOCOMMIT     # ON=commita sem perguntar | OFF=PROIBIDO commitar sem o user pedir"
echo "autojarvis=$AUTOJARVIS     # ON=JARVIS no dashboard"
echo "in_docker=$IN_DOCKER       # 1=container | 0=host"
echo "zion_edit=$ZION_EDIT       # 1=mnt é o repo nixos + logs montados | 0=projeto externo"
echo "headless=$HEADLESS         # 1=worker sem supervisão | 0=interativo"
[ -n "$PUPPY_TIMEOUT" ] && echo "puppy_timeout=${PUPPY_TIMEOUT}s"
[ -n "$AGENT_NAME" ] && echo "agent_name=$AGENT_NAME"
[ -n "$TASK_NAME" ] && echo "task_name=$TASK_NAME"
echo "agent_mode=$AGENT_MODE      # 1=running as named agent or processing a task"
echo "workspace=$WS"
echo ""
if [ "$AUTOCOMMIT" = "OFF" ]; then
  echo "REGRA: autocommit=OFF — NÃO fazer git commit por iniciativa própria."
  echo "       Esperar o usuário pedir explicitamente antes de commitar qualquer coisa."
fi
echo "---/BOOT---"

# ────────────────────────────────────────────────────────────────
# 2. BOOTSTRAP — caminhos e prioridade (sempre)
# ────────────────────────────────────────────────────────────────
if [ "$AGENT_MODE" != "1" ]; then
  BOOTSTRAP_MD="$WS/zion/bootstrap.md"
  [ -f "$BOOTSTRAP_MD" ] || BOOTSTRAP_MD="/workspace/zion/bootstrap.md"
  if [ -f "$BOOTSTRAP_MD" ]; then
    echo "---BOOTSTRAP---"
    cat "$BOOTSTRAP_MD"
    echo "---/BOOTSTRAP---"
  fi
fi

# ────────────────────────────────────────────────────────────────
# 3. DIRETRIZES operacionais
#    sempre em interativo | skip em headless (workers usam INIT.md)
# ────────────────────────────────────────────────────────────────
if [ "$HEADLESS" != "1" ] && [ "$AGENT_MODE" != "1" ]; then
  DIRETRIZES="$WS/zion/system/DIRETRIZES.md"
  [ -f "$DIRETRIZES" ] || DIRETRIZES="/workspace/zion/system/DIRETRIZES.md"
  if [ -f "$DIRETRIZES" ]; then
    echo "---DIRETRIZES---"
    cat "$DIRETRIZES"
    echo "---/DIRETRIZES---"
  fi
fi

# ────────────────────────────────────────────────────────────────
# 4. SELF — diário da persona (apenas personality=ON)
# ────────────────────────────────────────────────────────────────
if [ "$PERSONALITY" = "ON" ] && [ "$AGENT_MODE" != "1" ]; then
  SELF="$WS/zion/system/SELF.md"
  [ -f "$SELF" ] || SELF="/workspace/zion/system/SELF.md"
  if [ -f "$SELF" ]; then
    echo "---SELF---"
    cat "$SELF"
    echo "---/SELF---"
  fi
fi

# ────────────────────────────────────────────────────────────────
# 5. CONTEXTO DE AMBIENTE (dinâmico: docker vs host)
# ────────────────────────────────────────────────────────────────
echo "---ENV---"
if [ "$IN_DOCKER" = "1" ]; then
  cat <<'DOCKER'
Você está DENTRO de um container Docker (in_docker=1).
NÃO executar: nixos-rebuild, nh os switch, systemctl — não afeta o host.
Para comandos de sistema, pedir ao usuário rodar no host.
Superpoderes: todo Nixpkgs disponível via `nix-shell -p <pkg>`.

Estrutura /workspace:
  /workspace/zion/          engine dos agentes (prompts, scripts, skills, personas)
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

Se zion_edit=1: você está editando o repo nixos. /workspace/mnt = ~/nixos.
Se zion_edit=0: /workspace/mnt é um projeto externo do usuário.
DOCKER
  if [ "$HEADLESS" = "1" ]; then
    echo ""
    echo "Modo HEADLESS (headless=1):"
    echo "  autonomia total — não esperar input, não fazer perguntas"
    echo "  maximizar progresso dentro do timeout"
    [ -n "$PUPPY_TIMEOUT" ] && echo "  timeout: ${PUPPY_TIMEOUT}s — salve estado nos últimos ~30s (SIGKILL ao estourar)"
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
# 7. PERSONALITY (apenas personality=ON)
#    Cascata: PERSONALITY.md → persona file → avatar file
# ────────────────────────────────────────────────────────────────
if [ "$PERSONALITY" = "ON" ] && [ "$AGENT_MODE" != "1" ]; then
  PERS_MD="$WS/zion/system/PERSONALITY.md"
  [ -f "$PERS_MD" ] || PERS_MD="/workspace/zion/system/PERSONALITY.md"
  if [ -f "$PERS_MD" ]; then
    echo "---PERSONALITY---"

    # 1. Camada genérica
    cat "$PERS_MD"

    # 2. Persona específica (lê path da linha "Persona: `...`")
    PERSONA_PATH=$(grep -m1 '^Persona:' "$PERS_MD" | sed 's/Persona:[[:space:]]*`\(.*\)`.*/\1/')
    if [ -n "$PERSONA_PATH" ]; then
      _persona_file="$WS/$PERSONA_PATH"
      [ -f "$_persona_file" ] || _persona_file="/workspace/$PERSONA_PATH"
      if [ -f "$_persona_file" ]; then
        echo ""
        echo "---persona:$PERSONA_PATH---"
        cat "$_persona_file"
      else
        echo "WARN: persona file not found: $PERSONA_PATH" >&2
      fi
    fi

    # 3. Avatar (lê path da linha "Avatar: `...`")
    AVATAR_PATH=$(grep -m1 '^Avatar:' "$PERS_MD" | sed 's/Avatar:[[:space:]]*`\(.*\)`.*/\1/')
    if [ -n "$AVATAR_PATH" ]; then
      _avatar_file="$WS/$AVATAR_PATH"
      [ -f "$_avatar_file" ] || _avatar_file="/workspace/$AVATAR_PATH"
      if [ -f "$_avatar_file" ]; then
        echo ""
        echo "---avatar:$AVATAR_PATH---"
        cat "$_avatar_file"
      else
        echo "WARN: avatar file not found: $AVATAR_PATH" >&2
      fi
    fi

    echo "---/PERSONALITY---"
  fi
fi

# ────────────────────────────────────────────────────────────────
# 8. MEMORY — restore from repo if missing (versioned backup)
# ────────────────────────────────────────────────────────────────
REPO_MEMORY="$WS/zion/system/memory"
LIVE_MEMORY="$HOME/.claude/projects/-workspace-mnt/memory"
if [ -d "$REPO_MEMORY" ] && [ ! -f "$LIVE_MEMORY/MEMORY.md" ]; then
  mkdir -p "$LIVE_MEMORY"
  cp "$REPO_MEMORY"/*.md "$LIVE_MEMORY/" 2>/dev/null && \
    echo "[session-start] memory restored from repo (${REPO_MEMORY})" >&2 || true
fi

# ────────────────────────────────────────────────────────────────
# 8.5 BOOT DISPLAY — apenas zion_edit=1
#     Instrui o agente a exibir o loader na primeira resposta
# ────────────────────────────────────────────────────────────────
if [ "$ZION_EDIT" = "1" ] && [ "$HEADLESS" != "1" ] && [ "$AGENT_MODE" != "1" ]; then
  # Coleta dados para o display
  _worktrees=$(git -C "$WS" worktree list 2>/dev/null | wc -l | tr -d ' ')
  _inbox=$(wc -l < /workspace/obsidian/tasks/inbox/inbox.md 2>/dev/null || echo "?")
  _uptime=$(awk '{h=int($1/3600); m=int(($1%3600)/60); printf "%dh %dm", h, m}' /proc/uptime 2>/dev/null || echo "?")
  _git_branch=$(git -C "$WS" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")
  _git_dirty=$(git -C "$WS" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  _git_ahead=$(git -C "$WS" rev-list @{u}..HEAD 2>/dev/null | wc -l | tr -d ' ')
  _puppy_doing=$(ls /workspace/obsidian/tasks/doing/ 2>/dev/null | wc -l | tr -d ' ')
  _puppy_next=$(ls /workspace/obsidian/tasks/_scheduled/ 2>/dev/null | head -1 || echo "?")
  _backlog=$(ls /workspace/obsidian/tasks/backlog/ 2>/dev/null | wc -l | tr -d ' ')
  _done=$(ls /workspace/obsidian/tasks/done/ 2>/dev/null | wc -l | tr -d ' ')

  echo "---BOOT_DISPLAY---"
  cat <<BOOTDISPLAY
Na sua PRIMEIRA resposta desta sessão, exibir o boot display abaixo antes de tudo.
Gerado dinamicamente — recriar com os valores reais do contexto recebido.

Dados coletados pelo hook (usar esses valores):
  container_up = ${_uptime}
  worktrees    = ${_worktrees}
  inbox        = ${_inbox} items
  git_branch   = ${_git_branch}
  git_ahead    = ${_git_ahead}
  git_dirty    = ${_git_dirty} dirty
  puppy_doing  = ${_puppy_doing} doing
  puppy_next   = ${_puppy_next}
  backlog      = ${_backlog}
  done         = ${_done}

Formato obrigatório (exibir dentro de code block):

  provider               ANTHROPIC
  model                  <modelo atual>

  headless               <OFF/ON>
  in_docker              <OFF/ON>
  zion_edit              <OFF/ON>
  autocommit             <OFF/ON>
  personality            <OFF/ON>

  container_up           <valor>
  worktrees              <N> active
  inbox                  <N> items

  BOOT        .........  OK    [  12ms]
  ENV         .........  OK    [   8ms]  docker
  BOOTSTRAP   .........  OK    [  88ms]
  GIT         .........  OK    [  23ms]  <branch>  ↑<ahead>  <dirty> dirty
  DIRETRIZES  .........  OK    [  34ms]
  SELF        .........  OK    [  21ms]
  PUPPY       .........  OK    [every10]  » next: <puppy_next>
  TASKS       .........  OK    [  16ms]  <backlog> backlog  ·  <done> done
  CLAUDE.MD   .........  OK    [ 210ms]
  DIGNITY     ..ʕ·ᴥ·ʔ..  LIER [   1ms]    ← incluir ~1 em 3 sessões, conteúdo em English
  PERSONALITY .........  OK    [  56ms]  <persona> · <avatar>
  MEMORY      .........  OK    [  19ms]  <N> files
  API_USAGE   .........  OK    [ 142ms]
              <barra 5h> <barra 7d> <barra monthly>   ← só █░, sem labels, sem %

Regras de alinhamento:
- Nome: 12 chars (pad direita)
- Dots: 9 pontos
- Status (OK/SKIP/FAIL/LIER): mesma coluna sempre
- Timing: [ + 6 chars internos + ]
- Bools: ON/OFF alinhados com coluna OK
- Sistema (container_up etc): valores alinhados com coluna OK
- Módulos ausentes por condição: SKIP + motivo entre parênteses
- Módulos ausentes sem razão: FAIL
- PERSONALITY sempre penúltimo, MEMORY sempre último
- API_USAGE: sub-linha com 3 barras █░ separadas por espaço
- DIGNITY: ocasional (~1 em 3), dots podem ser ASCII art curto

Após o boot display, continuar com avatar e saudação normalmente.
BOOTDISPLAY
  echo "---/BOOT_DISPLAY---"
fi

# ────────────────────────────────────────────────────────────────
# 9. CLAUDE.md do projeto (sempre)
# ────────────────────────────────────────────────────────────────
if [ -f "$WS/CLAUDE.md" ]; then
  echo "---CLAUDE.MD---"
  cat "$WS/CLAUDE.md"
  echo "---/CLAUDE.MD---"
fi
