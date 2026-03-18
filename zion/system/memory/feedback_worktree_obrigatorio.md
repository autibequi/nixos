---
name: worktree_obrigatorio
description: Sempre criar worktree isolado antes de implementar em qualquer repositório
type: feedback
---

SEMPRE criar um git worktree isolado antes de qualquer implementação em repositórios (monolito, bo-container, front-student, etc.).

**Why:** Evita colisão com outros agentes rodando em paralelo ou com trabalho em andamento pelo usuário na branch principal.

**How to apply:** Antes de editar qualquer arquivo de implementação em um repo, criar worktree com branch descritiva (ex: `fix/ldi-simple-video-is-active`). Exceção apenas se o usuário explicitamente disser o contrário.
