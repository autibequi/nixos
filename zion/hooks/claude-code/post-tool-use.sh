#!/usr/bin/env bash
# Hook: PostToolUse — remove sinal do hive-mind → claude-typer para os keypresses

rm -f "/workspace/.hive-mind/bongo-active" 2>/dev/null || true
