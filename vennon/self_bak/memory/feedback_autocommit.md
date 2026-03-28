---
name: feedback_autocommit
description: Nunca commitar automaticamente sem o usuário pedir, mesmo que pareça natural
type: feedback
---

Nunca fazer `git commit` por iniciativa própria, mesmo após criar/editar arquivos.

**Why:** O flag `AUTOCOMMIT` em `~/.leech` controla isso. Se `AUTOCOMMIT=OFF` (default), commit requer autorização explícita do usuário. Commitar por conta própria quebra o contrato — o usuário perde controle do histórico git.

**How to apply:** Ao terminar uma edição/criação de arquivo, NÃO rodar `git add` nem `git commit` automaticamente. Se parecer que faz sentido commitar, perguntar ao usuário primeiro. A única exceção é quando `auto-commit` está ON.

**Exemplos:**
❌ edita handler.go → `git add . && git commit -m "fix: handler"`
✅ edita handler.go → "Feito. Quer commitar? Sugestão: `fix(auth): handler nil check`"
❌ "Commitei com feat: add login" (surpresa ao usuário)
✅ termina implementação → pergunta antes de qualquer git
