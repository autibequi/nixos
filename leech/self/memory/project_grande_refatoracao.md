---
name: project_grande_refatoracao
description: Grande Refatoração 2026-03-28 — consolidação de 16 docs em 5, status e o que ainda falta
type: project
---

Refatoração feita em 2026-03-28. Objetivo: consolidar 16 docs core em 5 arquivos canônicos.

**Status (2026-03-28):**

| Doc | Arquivo | Status |
|-----|---------|--------|
| SYSTEM.md | `self/SYSTEM.md` | ✓ criado (de BOOT.md) |
| AGENT.md | `self/agent.md` | ⚠ conteúdo existe, mas nome ainda lowercase |
| PERSONA.md | `self/PERSONALITY.md` | ⚠ conteúdo existe, mas nome errado + paths stale |
| DIRETRIZES.md | `self/DIRETRIZES.md` | ✓ ok |
| ARSENAL.md | `self/ARSENAL.md` | ✓ ok |

**Docs antigos que ainda existem e precisam ser absorvidos/removidos:**
- `agent.md` → renomear para `AGENT.md` + mesclar mapa de regras do RULES.md
- `PERSONALITY.md` → renomear para `PERSONA.md` + limpar paths stale (linha 85-89)
- `SOUL.md` → atualizar ponteiro de PERSONALITY.md → PERSONA.md
- `RULES.md` → mesclar "mapa de regras por tópico" no AGENT.md, depois remover
- `INIT.md` → bits únicos (boot flags, ~/.leech canal, hive-mind) vão pro SYSTEM.md, depois remover
- `GLOSSARY.md` → mesclar no SYSTEM.md, depois remover

**self_bak/ foi removido** — conteúdo único migrado (5 memory files + BOOT.md→SYSTEM.md).

**Why:** Reduzir tokens de boot de ~16 docs para 5. Corte de 83% no boot context.

**How to apply:** Ao encontrar referências a PERSONALITY.md, agent.md, RULES.md, INIT.md, GLOSSARY.md — saber que são os nomes antigos da refatoração incompleta. Os nomes canônicos são os 5 listados acima.
