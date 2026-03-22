#!/usr/bin/env bash
# Hook: PreToolUse
_ZION_FILE="${HOME:-/home/claude}/.zion"; [ -f "$_ZION_FILE" ] || _ZION_FILE="/.zion"
[ -f "$_ZION_FILE" ] && { set -a; source "$_ZION_FILE" 2>/dev/null || true; set +a; }
