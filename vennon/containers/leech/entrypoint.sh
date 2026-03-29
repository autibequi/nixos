#!/bin/bash

# nix-daemon em background (precisa rodar como root)
HOME=/root nix-daemon > /dev/null 2>&1 &

# UID/GID dinâmico — default 1000 se não definido
VENNON_UID="${VENNON_UID:-1000}"
VENNON_GID="${VENNON_GID:-1000}"

# Garantir user no /etc/passwd se UID != 1000
if [ "$VENNON_UID" != "1000" ]; then
    sed -i "s/^claude:x:1000:1000:/claude:x:${VENNON_UID}:${VENNON_GID}:/" /etc/passwd 2>/dev/null || true
    sed -i "s/^claude:x:1000:/claude:x:${VENNON_GID}:/" /etc/group 2>/dev/null || true
fi

# Dirs efêmeros + claude config
mkdir -p \
  /workspace/.ephemeral/locks /workspace/.ephemeral/notes /workspace/.ephemeral/scratch \
  /workspace/.ephemeral/cache \
  /tmp/vennon-locks \
  /home/claude \
  /home/claude/.cache \
  /home/claude/.claude \
  /home/claude/.claude/projects \
  /home/claude/.config/cursor \
  /home/claude/.config/opencode \
  /home/claude/.cursor \
  /home/claude/.agents \
  2>/dev/null

# Permissões — NÃO recursivo em /home/claude (bind mounts do host)
chown -R "${VENNON_UID}:${VENNON_GID}" /workspace/.ephemeral /tmp/vennon-locks 2>/dev/null || true
chown "${VENNON_UID}:${VENNON_GID}" /home/claude 2>/dev/null || true
chown -R "${VENNON_UID}:${VENNON_GID}" /home/claude/.cache 2>/dev/null || true
chmod -R u+rwX /home/claude/.cache 2>/dev/null || true

# /workspace/target is a real bind mount (set in compose)

# Ambiente
export HOME=/home/claude
export USER=claude
export LOGNAME=claude

# Source ~/.vennon (canal host ↔ container)
if [ -f /home/claude/.vennon ]; then
    set -a
    . /home/claude/.vennon 2>/dev/null || true
    set +a
fi


# Session-start hook
_session_hook="/home/claude/.claude/hooks/session-start.sh"
[ -f "$_session_hook" ] || _session_hook="/workspace/self/hooks/claude-code/session-start.sh"
if [ -f "$_session_hook" ]; then
    HOME=/home/claude USER=claude LOGNAME=claude \
        setpriv --reuid="${VENNON_UID}" --regid="${VENNON_GID}" --keep-groups \
        /bin/bash "$_session_hook" >/dev/null 2>&1 || true
fi

# Drop privileges e executa comando
exec setpriv --reuid="${VENNON_UID}" --regid="${VENNON_GID}" --keep-groups "$@"
