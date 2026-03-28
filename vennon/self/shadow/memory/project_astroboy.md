---
name: Projeto Astroboy
description: Pipeline autônomo por projeto — agents processam tasks em kanban Obsidian sem intervenção humana (exceto gates)
type: project
---

Projeto em `obsidian/projects/astroboy/` — design de pipeline autônomo onde múltiplos agentes processam tasks dentro de um projeto Obsidian.

**Why:** Hoje agentes rodam rondas independentes (DASHBOARD global). Pedro quer que projetos tenham seu próprio kanban de tasks onde agentes criam, investigam, implementam e validam automaticamente.

**How to apply:**
- Escopo genérico (qualquer projeto, não só Estratégia)
- Semi-automático: investigação e brainstorm rodam sozinhos, implementação precisa OK humano
- Hefesto (#sonnet, ronda every60min) está desenhando o sistema incrementalmente em `projects/astroboy/design/`
- Docs de referência na pasta: `fake dev agente workflow.md` (simulação completa), `skill-flow-jira.md` (flowchart)
- Primeiro ciclo (2026-03-28): `anatomy.md` e `task-format.md` criados

Decisões do Pedro:
- Obsidian-first — tudo em markdown, legível por humano e agente
- Usar infraestrutura existente (DASHBOARD, Hermes, yaa tick) — não reinventar
- A ideia é que um card no DASHBOARD global trigga um "project orchestrator" que coordena sub-agentes dentro do projeto
