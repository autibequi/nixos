#!/bin/bash

HOME=/root nix-daemon > /dev/null 2>&1 &

mkdir -p \
  /workspace/.ephemeral/locks /workspace/.ephemeral/notes /workspace/.ephemeral/scratch \
  /workspace/.ephemeral/cache \
  /tmp/leech-locks \
  /home/claude \
  /home/claude/.cache/opencode \
  2>/dev/null
# OpenCode/Bun precisa de ~/.cache/opencode gravável por uid 1000 (EACCES se faltar ou chown falhar)
chown -R 1000:1000 /workspace/.ephemeral /tmp/leech-locks /home/claude 2>/dev/null || true
chmod -R u+rwX /home/claude/.cache 2>/dev/null || true
chown -R 1000:1000 /workspace/obsidian/agents/cron 2>/dev/null || true

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
    setpriv --reuid=1000 --regid=1000 --keep-groups \
    /bin/bash "$_session_hook" >/dev/null 2>&1 || true
fi

exec setpriv --reuid=1000 --regid=1000 --keep-groups "$@"
