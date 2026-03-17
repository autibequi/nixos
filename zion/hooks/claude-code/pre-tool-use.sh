#!/usr/bin/env bash
# Hook: PreToolUse — sinaliza pro claude-typer que Claude está ativo
# Toca arquivo de sinal no hive-mind → daemon no host lê e manda keypresses pro bongocat

SIGNAL_DIR="/workspace/.hive-mind"
SIGNAL_FILE="$SIGNAL_DIR/bongo-active"

mkdir -p "$SIGNAL_DIR" 2>/dev/null
touch "$SIGNAL_FILE" 2>/dev/null || true
