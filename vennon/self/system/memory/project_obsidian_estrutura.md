---
name: project-obsidian-estrutura-consolidada
type: project
updated: 2026-03-28
---

Obsidian foi consolidado em 2026-03-28. Estrutura atual:

```
obsidian/
├── bedrooms/     — 11 agentes ativos (coruja, gandalf, ghost, hefesto, hermes, keeper, paperboy, performance, sage, tamagochi, venture)
├── DASHBOARD.md  — kanban ativo (único, na raiz)
├── inbox/        — mensagens entrantes
├── memory/       — memória geral do sistema
├── outbox/       — saída para o Pedro
├── projects/     — projetos (imobiltracker, mudanca-cwb, etc)
├── vault/        — (vazio — era o sistema legado)
├── wiki/         — wiki geral
└── _trash/       — staging de deleção (vault-bedrooms-20260328)
```

**Why:** Havia dois sistemas paralelos — vault/bedrooms (23 agentes, estrutura pesada) e bedrooms/ (7 agentes, estrutura enxuta). O vault foi consolidado e movido para _trash.

**How to apply:** `bedrooms/` é o source of truth para agentes. `vault/` está vazio e pode ser removido. Ao criar novos agentes, usar estrutura de bedrooms/ (BRIEFING.md + memory.md).
