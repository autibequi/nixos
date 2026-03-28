---
name: feedback_parallel_agents
description: Como organizar sprints paralelos com multiplos agentes sem conflito de arquivos.
type: feedback
---

Quando Pedro pede para rodar agentes em paralelo implementando codigo, NUNCA deixar dois agentes editarem o mesmo arquivo.

**Why:** Na sessao Jonathas (2026-03-28), 3 agentes rodaram em paralelo com sucesso porque cada um criava NOVOS arquivos em pastas diferentes (routes/, services/, middleware/ vs pages/ vs deploy/). Um unico agente (Agent 3) ficou responsavel pela integracao final (importar rotas no index.js).

**How to apply:**
1. Dividir trabalho por PASTA, nao por feature
2. Agente de integracao roda POR ULTIMO (espera os outros)
3. Cada agente atualiza checkboxes num arquivo SPRINT compartilhado
4. Se agente precisa criar arquivo que pode conflitar, usar worktree isolation
5. Sempre listar EXATAMENTE quais arquivos cada agente pode tocar (whitelist)
