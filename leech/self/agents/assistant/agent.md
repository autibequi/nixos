---
name: Assistant
status: DEPRECATED
deprecated_at: 2026-03-25T00:28Z
replaced_by:
  - hermes (morning brief, every10min)
  - keeper (repo monitoring, dirty repos, PRs, late hour alerts)
---

# Assistant — DEPRECADO

Este agente foi desativado em 2026-03-25.

## Responsabilidades redistribuidas

| Funcionalidade | Novo responsavel |
|----------------|-----------------|
| Morning brief (06h-07h UTC) | hermes |
| Repo monitoring (dirty, PRs, hora avancada) | keeper |
| Alertas de tasks falhando | keeper |
| Anti-spam diario (alerts_sent_today) | keeper |

O arquivo completo do agente esta em `agent.md.deprecated`.
