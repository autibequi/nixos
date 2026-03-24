#!/bin/bash
# Alinhar com o usuário do host (bind mounts gravam UID/GID numéricos).
RUN_UID="${LEECH_CONTAINER_UID:-1000}"
RUN_GID="${LEECH_CONTAINER_GID:-1000}"

HOME=/root nix-daemon > /dev/null 2>&1 &

mkdir -p \
  /workspace/.ephemeral/locks /workspace/.ephemeral/notes /workspace/.ephemeral/scratch \
  /workspace/.ephemeral/cache \
  /tmp/leech-locks \
  /home/claude \
  /home/claude/.cache/opencode \
  2>/dev/null
# OpenCode/Bun precisa de ~/.cache/opencode gravável pelo RUN_UID (EACCES se faltar ou chown falhar)
# ATENÇÃO: NÃO usar chown -R em /home/claude inteiro — recursão entra nos bind mounts do host
# (.claude, .cursor, .leech, etc.) e muda dono de arquivos do host para root/1000.
chown -R "${RUN_UID}:${RUN_GID}" /workspace/.ephemeral /tmp/leech-locks 2>/dev/null || true
chown "${RUN_UID}:${RUN_GID}" /home/claude 2>/dev/null || true
chown -R "${RUN_UID}:${RUN_GID}" /home/claude/.cache 2>/dev/null || true
chmod -R u+rwX /home/claude/.cache 2>/dev/null || true
chown -R "${RUN_UID}:${RUN_GID}" /workspace/obsidian/agents/cron 2>/dev/null || true
# cursor-agent precisa escrever em ~/.config/cursor (token de login)
mkdir -p /home/claude/.config/cursor 2>/dev/null || true
chown "${RUN_UID}:${RUN_GID}" /home/claude/.config/cursor 2>/dev/null || true

export HOME=/home/claude
export USER=claude
export LOGNAME=claude
if [ -f /home/claude/.leech ]; then set -a; . /home/claude/.leech 2>/dev/null || true; set +a; fi

# Mesmo stdout do hook session-start → .cursor/session-boot.md (tee dentro do hook).
# Corre no arranque do container para o Cursor ter o ficheiro antes da primeira sessão Claude Code.
_session_hook="/home/claude/.claude/hooks/session-start.sh"
[ -f "$_session_hook" ] || _session_hook="/workspace/self/hooks/claude-code/session-start.sh"
if [ -f "$_session_hook" ]; then
  HOME=/home/claude USER=claude LOGNAME=claude \
    setpriv --reuid="${RUN_UID}" --regid="${RUN_GID}" --keep-groups \
    /bin/bash "$_session_hook" >/dev/null 2>&1 || true
fi

exec setpriv --reuid="${RUN_UID}" --regid="${RUN_GID}" --keep-groups "$@"
