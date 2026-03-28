---
name: meta/skill
description: Skills de meta-evolução — ferramentas para explicar, visualizar e evoluir outras skills do sistema.
---

# meta/skill — Índice

| Sub-skill | Comando | O que faz |
|-----------|---------|-----------|
| `explain` | `/meta:skill:explain` | Explica qualquer skill visualmente — flowchart Mermaid no holodeck |
| `evolve` | `/meta:skill:evolve` | Evolução empírica via benchmark — gera N variações, roda em paralelo, compara e propõe melhoria |

---

## evolve — Uso rápido

```
/meta:skill:evolve <skill_path> [--n=5] [--benchmark=<path>] [--model=haiku]
```

Benchmark padrão: `self/skills/meta/skill/evolve/benchmark_default.md` (5 problemas do monolito)
