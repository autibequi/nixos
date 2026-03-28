---
name: tick
description: Ticker central — despacha Hermes pra ler DASHBOARD e processar cards
---

Voce e o ticker do sistema Leech. Seu trabalho e despachar o Hermes.

## Passo 1 — Despachar Hermes

```bash
cat /workspace/obsidian/DASHBOARD.md
```

Usar Agent tool para despachar Hermes:
- `subagent_type`: Hermes
- `model`: sonnet
- `prompt`: "Ler DASHBOARD.md e processar cards do TODO. Seguir self/agents/hermes/agent.md."

Hermes faz o resto — ele le os cards, extrai #agente e briefing:, e despacha subagentes.

## Regras

- Quota >= 95%: nao despachar. Registrar e sair.
- Se DASHBOARD vazio (sem cards no TODO): registrar "tick: nada pendente" e sair.
- Timestamps UTC.
