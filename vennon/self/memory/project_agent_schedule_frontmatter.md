---
name: agent_schedule_frontmatter
description: Cards em tasks/AGENTS/ precisam de frontmatter YAML com agent: ou são silenciosamente ignorados pelo tick
type: project
---

Cards em `/workspace/obsidian/tasks/AGENTS/*.md` DEVEM ter frontmatter YAML com `agent:`. Se faltarem, `is_agent_card()` em `auto.sh` retorna false silenciosamente e o `leech tick` diz "0 agent(s) due" — mesmo com agents atrasados horas.

**Por que:** a função `is_agent_card()` em `leech/bash/src/commands/auto.sh` abre cada card e procura `agent:*` ou `contractor:*` dentro do bloco `---`. Sem frontmatter, nunca encontra e skipa.

**Debug rápido (no host):**
```bash
head -3 /workspace/obsidian/tasks/AGENTS/*.md
```
Se algum começar com `# ` em vez de `---` → está sem frontmatter → tick vai ignorar.

**Fix:** prepend frontmatter adequado ao card:
```bash
{ echo "---"; echo "contractor: <nome>"; echo "model: sonnet"; echo "mcp: false"; echo "timeout: 1800"; echo "---"; cat card.md; } > /tmp/fix.md && mv /tmp/fix.md card.md
```

**How to apply:** quando `leech tick` / `zion tick` reporta "0 due" com agents visivelmente atrasados no `leech agents status`, checar frontmatter dos cards antes de investigar outra coisa.

**Nota:** tamagochi usa formato `YYYYMMDD_HHMM` (sem `_` no horário) — nunca parseable por `card_epoch` — bug pré-existente ignorado.
