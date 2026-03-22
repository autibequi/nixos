#!/usr/bin/env bash
# Hook: PreToolUse
_LEECH_FILE="${HOME:-/home/claude}/.leech"; [ -f "$_LEECH_FILE" ] || _LEECH_FILE="/.leech"
[ -f "$_LEECH_FILE" ] && { set -a; source "$_LEECH_FILE" 2>/dev/null || true; set +a; }
