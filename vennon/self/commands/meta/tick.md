---
name: meta:tick
description: Despacha Hermes pra ler DASHBOARD e processar cards (= yaa tick)
---

# /meta:tick — Ticker

Despachar Hermes para processar o DASHBOARD.

```bash
cat /workspace/obsidian/DASHBOARD.md
```

Usar Agent tool:
- subagent_type: Hermes
- model: sonnet
- prompt: "Ler DASHBOARD.md e processar cards do TODO. Seguir self/ego/hermes/agent.md."

Hermes faz o resto.

## Regras
- Quota >= 95%: nao despachar. Registrar e sair.
- DASHBOARD vazio: registrar "tick: nada pendente" e sair.
