---
name: feedback_container_readonly
description: /home/claude/.claude/ e /workspace/host/ são read-only no container — persistir APENAS em /workspace/self/
type: feedback
---

No container Leech, apenas `/workspace/self/`, `/workspace/home/` e `/workspace/obsidian/` são montados com escrita (rw). Os outros são read-only:

- `/home/claude/.claude/` → read-only (ro)
- `/workspace/host/` → read-only (ro)

**Why:** O host monta esses diretórios com proteção para evitar que o container sobrescreva configurações do host diretamente.

**How to apply:** Toda persistência de configs, memórias, skills, traços de comportamento deve ir para `/workspace/self/`. Se tentar escrever em outro lugar e der EROFS, não tentar workarounds — emitir AVISO explícito ao usuário de que não foi possível persistir.
