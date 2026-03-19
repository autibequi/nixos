---
name: feedback_autocommit
description: Nunca commitar automaticamente sem o usuário pedir, mesmo que pareça natural
type: feedback
---

Nunca fazer `git commit` por iniciativa própria, mesmo após criar/editar arquivos.

**Why:** O flag `auto-commit` em `/workspace/.ephemeral/auto-commit` controla isso. Se não existe, commit requer autorização explícita do usuário. Commitar por conta própria quebra o contrato — o usuário perde controle do histórico git.

**How to apply:** Ao terminar uma edição/criação de arquivo, NÃO rodar `git add` nem `git commit` automaticamente. Se parecer que faz sentido commitar, perguntar ao usuário primeiro. A única exceção é quando `auto-commit` está ON.
