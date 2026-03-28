---
name: feedback-obsidian-deletar-via-trash
type: feedback
updated: 2026-03-28
---

Ao remover arquivos do obsidian, NUNCA deletar direto — mover para `_trash/` na raiz do obsidian primeiro.

**Why:** O usuário quer poder revisar o que foi removido antes de decidir apagar de vez. Hard delete imediato é inaceitável.

**How to apply:** Qualquer `rm -rf` em /workspace/obsidian/ deve virar `mv <pasta> /workspace/obsidian/_trash/<nome>-<data>`. Só deleta quando o usuário pedir explicitamente.
