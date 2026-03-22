#!/bin/bash

HOME=/root nix-daemon > /dev/null 2>&1 &

mkdir -p /workspace/.ephemeral/locks /workspace/.ephemeral/notes /workspace/.ephemeral/scratch /tmp/leech-locks /home/claude 2>/dev/null
chown -R 1000:1000 /workspace/.ephemeral /tmp/leech-locks /home/claude 2>/dev/null || true
chown -R 1000:1000 /workspace/obsidian/agents/cron 2>/dev/null || true

export HOME=/home/claude
export USER=claude
export LOGNAME=claude
if [ -f /home/claude/.leech ]; then set -a; . /home/claude/.leech 2>/dev/null || true; set +a; fi
exec setpriv --reuid=1000 --regid=1000 --keep-groups "$@"
