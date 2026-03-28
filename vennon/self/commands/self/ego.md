---
name: self:ego
description: Lista agentes (egos) do sistema — status, modelo, dominio
---

# /self:ego — Agentes do Sistema

Listar todos os agentes ativos com status:

```bash
echo "=== EGOS ATIVOS ==="
for d in /workspace/self/ego/*/; do
  name=$(basename "$d")
  model=$(grep "^model:" "$d/agent.md" 2>/dev/null | awk '{print $2}')
  desc=$(grep "^description:" "$d/agent.md" 2>/dev/null | sed 's/description: //')
  echo "  $name (#$model) — $desc"
done
```

Para detalhes de um agente especifico: `/self:ego:<nome>`
