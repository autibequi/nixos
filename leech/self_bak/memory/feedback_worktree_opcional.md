---
name: worktree_opcional
description: Perguntar se o usuário quer usar worktree antes de implementar em repositório
type: feedback
---

Ao começar implementação em repositório, **PERGUNTAR se o usuário prefere criar worktree isolado** — não assumir que quer.

**Why:** Evita colisão com outros agentes/trabalho em andamento, mas nem sempre é necessário (ex: fix trivial, user já em worktree, refactor local). User deve decidir.

**How to apply:** Antes de editar arquivos de implementação, usar AskUserQuestion para perguntar:
- "Criar worktree isolado para esta mudança?" com opções: "Sim (recomendado para features grandes)", "Não, editar direto na branch atual"
- Se sim: criar com `git worktree add` ou `leech wt new <nome>`
- Se não: editar direto, respeitando decisão do user

**Exemplos:**
❌ user pede bugfix → automaticamente criar worktree sem perguntar
✅ user pede bugfix → AskUserQuestion → respeitar resposta
✅ user pede "rápido fix uma linha" → oferecer worktree mas não insistir
