---
name: obsidian:project
description: Gestao de projetos — criar, regras de briefing, listar. Sub-comandos: new, rules, list.
---

# /meta:project — Gestao de Projetos

## Sub-comandos

| Comando | O que faz |
|---------|-----------|
| `/meta:project new` | Wizard passo a passo pra criar projeto (agente, briefing, card) |
| `/meta:project rules` | Regras obrigatorias do BRIEFING.md |
| `/meta:project list` | Lista projetos ativos com status |

## /meta:project list

```bash
echo "=== PROJETOS ==="
for d in /workspace/obsidian/projects/*/; do
  name=$(basename "$d")
  brief="sem briefing"
  [ -f "$d/BRIEFING.md" ] && brief="BRIEFING.md ✓"
  echo "  $name — $brief"
done
echo ""
echo "=== CARDS NO DASHBOARD ==="
grep "briefing:projects/" /workspace/obsidian/DASHBOARD.md
```

## Regras gerais

Ver `self/superego/` para regras globais do sistema (DASHBOARD, briefings, agentes).
Ver `self/commands/meta/project/rules.md` para regras especificas de BRIEFING.md.
