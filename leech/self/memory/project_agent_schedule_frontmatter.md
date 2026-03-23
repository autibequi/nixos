---
name: agent_schedule_frontmatter
description: Cards em _schedule/ precisam de frontmatter YAML com contractor:/agent: ou são silenciosamente ignorados pelo tick
type: project
---

Cards em `~/.ovault/Work/agents/_schedule/*.md` (ou `/workspace/obsidian/agents/_schedule/`) DEVEM ter frontmatter YAML com `contractor:` ou `agent:`. Se faltarem, `is_agent_card()` em `auto.sh` retorna false silenciosamente e o `leech tick` diz "0 agent(s) due" — mesmo com agents atrasados horas.

**Por que:** a função `is_agent_card()` em `leech/bash/src/commands/auto.sh` abre cada card e procura `agent:*` ou `contractor:*` dentro do bloco `---`. Sem frontmatter, nunca encontra e skipa.

**Debug rápido (no host):**
```bash
head -3 ~/.ovault/Work/agents/_schedule/*.md
```
Se algum começar com `# ` em vez de `---` → está sem frontmatter → tick vai ignorar.

**Fix:** prepend frontmatter adequado ao card:
```bash
{ echo "---"; echo "contractor: <nome>"; echo "model: sonnet"; echo "mcp: false"; echo "timeout: 1800"; echo "---"; cat card.md; } > /tmp/fix.md && mv /tmp/fix.md card.md
```

**How to apply:** quando `leech tick` / `zion tick` reporta "0 due" com agents visivelmente atrasados no `leech agents status`, checar frontmatter dos cards antes de investigar outra coisa.

**Nota:** tamagochi usa formato `YYYYMMDD_HHMM` (sem `_` no horário) — nunca parseable por `card_epoch` — bug pré-existente ignorado.
