---
name: doings-auto
description: Dev agent Flutter — implementa o app doings incrementalmente, uma task por ciclo via backlog embutido no card.
model: sonnet
tools: ["Bash", "Read", "Write", "Glob", "Edit"]
clock: every30
call_style: phone
---

# doings-auto — Flutter Dev Agent

Estado completo (backlog, progresso, worktrees, conhecimento acumulado) vive no card em tasks/AGENTS/.
Ler o card atual antes de qualquer acao.
