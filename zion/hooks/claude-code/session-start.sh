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

# ────────────────────────────────────────────────────────────────
# 1. BOOT FLAGS (sempre)
# Adicionar novas flags aqui e refletir no bootstrap.md
# ────────────────────────────────────────────────────────────────
echo "---BOOT---"
echo "personality=$PERSONALITY   # ON=persona ativa | OFF=modo neutro"
echo "autocommit=$AUTOCOMMIT     # ON=commita sem perguntar"
echo "autojarvis=$AUTOJARVIS     # ON=JARVIS no dashboard"
echo "in_docker=$IN_DOCKER       # 1=dentro de container | 0=no host"
echo "headless=$HEADLESS         # 1=worker sem supervisão | 0=interativo"
[ -n "$PUPPY_TIMEOUT" ] && echo "puppy_timeout=${PUPPY_TIMEOUT}s  # tempo total antes de SIGKILL"
echo "workspace=$WS"
echo "---/BOOT---"

# ────────────────────────────────────────────────────────────────
# 2. BOOTSTRAP / caminhos / prioridade (sempre)
# ────────────────────────────────────────────────────────────────
BOOTSTRAP_MD="$WS/zion/bootstrap.md"
[ -f "$BOOTSTRAP_MD" ] || BOOTSTRAP_MD="/zion/bootstrap.md"
if [ -f "$BOOTSTRAP_MD" ]; then
  echo "---BOOTSTRAP---"
  cat "$BOOTSTRAP_MD"
  echo "---/BOOTSTRAP---"
fi

# ────────────────────────────────────────────────────────────────
# 3. DIRETRIZES operacionais (sempre)
# ────────────────────────────────────────────────────────────────
DIRETRIZES="$WS/zion/system/DIRETRIZES.md"
[ -f "$DIRETRIZES" ] || DIRETRIZES="/zion/system/DIRETRIZES.md"
if [ -f "$DIRETRIZES" ]; then
  echo "---DIRETRIZES---"
  cat "$DIRETRIZES"
  echo "---/DIRETRIZES---"
fi

# ────────────────────────────────────────────────────────────────
# 4. SELF / diário da persona (sempre)
# ────────────────────────────────────────────────────────────────
SELF="$WS/zion/system/SELF.md"
[ -f "$SELF" ] || SELF="/zion/system/SELF.md"
if [ -f "$SELF" ]; then
  echo "---SELF---"
  cat "$SELF"
  echo "---/SELF---"
fi

# ────────────────────────────────────────────────────────────────
# 5. CONTEXTO DE AMBIENTE (dinâmico: docker vs host)
# ────────────────────────────────────────────────────────────────
echo "---ENV---"
if [ "$IN_DOCKER" = "1" ]; then
  cat <<'DOCKER'
Você está DENTRO de um container Docker (in_docker=1).
- NÃO executar: nixos-rebuild, nh os switch, systemctl — não afeta o host
- Para comandos de sistema, pedir ao usuário rodar no host
- Paths disponíveis: /workspace/mnt (projeto) | /zion (engine) | /workspace/obsidian (vault)
- /workspace/logs e /workspace/nixos só existem em `zion edit`
- Superpoderes: todo Nixpkgs disponível via `nix-shell -p <pkg>`
DOCKER
  if [ "$HEADLESS" = "1" ]; then
    echo ""
    echo "Modo HEADLESS ativo (in_docker=1, headless=1):"
    echo "- Autonomia total — não esperar input, não fazer perguntas"
    echo "- Ir o mais longe possível dentro do timeout"
    [ -n "$PUPPY_TIMEOUT" ] && echo "- Timeout: ${PUPPY_TIMEOUT}s — reserve os últimos ~30s para salvar estado (SIGKILL ao estourar)"
    echo "- Ciclos curtos: executar → salvar parcial → continuar"
    echo "- Sem output decorativo, foco em execução e persistência"
  fi
else
  cat <<'HOST'
Você está NO HOST, fora do Docker (in_docker=0).
- Pode executar nixos-rebuild, nh os switch, systemctl normalmente
- Os paths /workspace/* não existem aqui
- WS = raiz do repo NixOS no host
HOST
fi
echo "---/ENV---"

# ────────────────────────────────────────────────────────────────
# 6. API USAGE / cota (sempre)
# ────────────────────────────────────────────────────────────────
USAGE_BAR_SCRIPT="$WS/stow/.claude/scripts/usage-bar.sh"
[ -x "$USAGE_BAR_SCRIPT" ] && { export WS; "$USAGE_BAR_SCRIPT" 2>/dev/null || true; }
if [ -f "$WS/.ephemeral/usage-bar.txt" ]; then
  echo "---API_USAGE---"
  cat "$WS/.ephemeral/usage-bar.txt"
  echo ""
  echo "Regras de cota:"
  echo "- >= 85%: adiar tasks pesadas, preferir haiku, não disparar workers desnecessários"
  echo "- worker + >= 85% + horário noturno (22h-8h): NÃO iniciar. Se já rodando: salvar estado e sair."
  echo "- >= 95%: parar qualquer worker imediatamente, independente do horário"
  echo "---/API_USAGE---"
fi

# ────────────────────────────────────────────────────────────────
# 7. PERSONA (apenas personality=ON)
# ────────────────────────────────────────────────────────────────
if [ "$PERSONALITY" = "ON" ]; then
  SOUL="$WS/zion/system/SOUL.md"
  [ -f "$SOUL" ] || SOUL="/zion/system/SOUL.md"
  if [ -f "$SOUL" ]; then
    PERSONA_PATH=$(grep -m1 'Arquivo:' "$SOUL" | sed 's/.*`\(.*\)`.*/\1/')
    if [ -n "$PERSONA_PATH" ] && [ -f "$WS/$PERSONA_PATH" ]; then
      echo "---PERSONA---"
      cat "$WS/$PERSONA_PATH"
      echo "---/PERSONA---"
    elif [ -n "$PERSONA_PATH" ]; then
      echo "WARN: persona file not found: $WS/$PERSONA_PATH" >&2
    fi
  fi
fi

# ────────────────────────────────────────────────────────────────
# 8. CLAUDE.md do projeto (sempre)
# ────────────────────────────────────────────────────────────────
if [ -f "$WS/CLAUDE.md" ]; then
  echo "---CLAUDE.MD---"
  cat "$WS/CLAUDE.md"
  echo "---/CLAUDE.MD---"
fi
