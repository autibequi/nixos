# 🔀 Gestão de Worktrees — Guia Completo

Sistema de rastreamento de worktrees isolados. Quando você pede um trabalho com `#worktree`, tudo fica isolado, versionado e com visibilidade total.

---

## 🎯 Objetivo

```
Antes (sem worktree):
  ❌ Mudanças na main
  ❌ Sem rollback fácil
  ❌ Contextual mixing

Agora (com worktree):
  ✓ Branch isolada
  ✓ Git separado
  ✓ Dashboard de progresso
  ✓ Fácil revert/merge
```

---

## 🔄 Fluxo Completo

```
┌─────────────────────────────────────────────────────────┐
│ USER: "implementa X com #worktree"                      │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
        ┌─ EnterWorktree called
        │  • git worktree add
        │  • nova branch
        │  • cd isolado
        │
        ├─ Hook: worktree-enter
        │  • scripts/worktree-manager.sh init
        │  • Registra em .worktrees-registry.json
        │  • Atualiza vault/worktrees.md
        │
        ▼
┌─────────────────────────────────────────────────────────┐
│ 🚀 Work (isolado)                                       │
│  • Edito arquivos                                       │
│  • Faço commits                                         │
│  • Rodo testes                                          │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
        /worktree-status
        • Mostra branch atual
        • Mudanças desde entrada
        • Tempo decorrido
        • Link pra artefatos
        │
        ▼
┌─────────────────────────────────────────────────────────┐
│ 📝 Proposta de Merge                                    │
│  • Crio vault/worktrees/<name>/proposal.md              │
│  • Descrevo o que faz                                   │
│  • Link pra diff                                        │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
        ExitWorktree (action: keep|remove)
        • Finaliza branch
        • Move artefatos pra vault/_agent/reports/
        • Remove do registro
        │
        ▼
┌─────────────────────────────────────────────────────────┐
│ ✅ Pronto pra Review/Merge                              │
│  Tudo documentado e rastreado                           │
└─────────────────────────────────────────────────────────┘
```

---

## 📊 Dashboard: `vault/worktrees.md`

Documento vivo que mostra:

```markdown
| Nome | Objetivo | Branch | Status | Entrada |
|------|----------|--------|--------|---------|
| propositor-bootstrap | Reduzir loops | propositor/bootstrap | 🟢 | 2026-03-14 14:22 |
```

Cada worktree tem:
- **README.md** — contexto e objetivo
- **changes.md** — diff summarizado
- **proposal.md** — o que vai fazer quando merge

---

## 🛠️ Comandos

### Status

```bash
/worktree-status           # Dashboard do worktree atual
/worktree-status --list    # Lista todos os worktrees
```

Output:
```
🔀 WORKTREE: propositor-bootstrap

├─ Branch: propositor/bootstrap-single-pass
├─ Objetivo: Reduzir loops bootstrap: 5→1
├─ Entrado: 2026-03-14 14:22:03 (2h 47min)
│
├─ 📝 Mudanças:
│  ├─ Arquivos modificados: 2
│  ├─ Adições: 45 linhas
│  ├─ Deleções: 18 linhas
│
├─ 📂 Artefatos:
│  └─ vault/worktrees/propositor-bootstrap/
│     ├─ README.md
│     ├─ changes.md
│     └─ proposal.md
```

---

## 💾 Artefatos por Worktree

```
vault/
└── worktrees/
    └── propositor-bootstrap/
        ├── README.md          ← contexto
        ├── changes.md         ← git diff --stat
        └── proposal.md        ← pitch de merge
```

**README.md** — contexto para humano entender:
```markdown
# Propositor Bootstrap Simplificado

**Branch:** propositor/bootstrap-single-pass
**Objetivo:** Reduzir 5 loops bootstrap → 1 pass único
**Por quê:** Acelerar startup em 60%, remover redundância

## Mudanças
- bootstrap.sh: parse único do kanban
- makefile: novo target

## Risk
- Baixo — só refatora, sem comportamento novo
```

**changes.md** — resumo técnico:
```markdown
# Changes: propositor-bootstrap

## Diff Summary
- bootstrap.sh: +42 -18 (24 linhas net)
- makefile: +3 -0 (3 linhas)

## Key Changes
1. Consolidate 5 kanban parses → 1
2. Use arrays em bash pra reusability
3. Remover duplicação de grep
```

**proposal.md** — pitch pro merge:
```markdown
# Proposta: Merge propositor-bootstrap

**Status:** Ready for Review

Reduz bootstrap loop duplicado de 5 passes pra 1.
Antes: 8.2s
Depois: 3.1s

Baseline benchmarks em [[artefacts/propositor-bootstrap/benchmark|benchmark.txt]]

Recomendação: Mergear depois do próximo release.
```

---

## 🔗 Integração com Kanban

Card no kanban aponta pro worktree:

```markdown
- [ ] **propositor-bootstrap** [worker-3] `#sonnet` #worktree
  → Worktrees: [[worktrees#propositor-bootstrap|dashboard]]
  → Proposta: [[worktrees/propositor-bootstrap/proposal|review me]]
```

Quando concluído:
```markdown
- [x] **propositor-bootstrap** [worker-3] #done 2026-03-14
  → Resultado: [[_agent/reports/worktree-propositor-bootstrap-20260314-1452|artefato]]
```

---

## 🧠 Mental Model

```
Main Branch
├─ Worktree A (isolado)
│  └─ feature-x
│     ├─ commit 1
│     ├─ commit 2
│     └─ Pronto pra merge
├─ Worktree B (isolado)
│  └─ fix-bug-y
│     ├─ commit 1
│     └─ Esperando review
└─ Clean (você está aqui)
```

Cada worktree é uma **realidade paralela** com seu próprio histórico git, branch, e artefatos. Não contamina main, não contamina outros worktrees.

---

## ⚙️ Technical Details

### Registry: `.worktrees-registry.json`

```json
{
  "propositor-bootstrap": {
    "branch": "propositor/bootstrap-single-pass",
    "objective": "Reduzir loops bootstrap",
    "entered": "2026-03-14 14:22:03",
    "status": "in-progress"
  },
  "fix-typo": {
    "branch": "fix/typo-claude-md",
    "objective": "Fix typo em CLAUDE.md linha 42",
    "entered": "2026-03-14 12:10:15",
    "status": "ready"
  }
}
```

### Hook: `worktree-enter.json`

Roda automaticamente quando você chama `EnterWorktree`:
```bash
cd /workspace && ./scripts/worktree-manager.sh update-dashboard
```

Atualiza `vault/worktrees.md` com novo card.

---

## 🚀 Quick Start

```bash
# Você pede:
"implementa feature X com #worktree"

# Acontece:
# 1. EnterWorktree → git worktree add
# 2. Hook → worktree-manager init
# 3. Dashboard atualizado em vault/worktrees.md

# Você trabalha normalmente
# Quando termina:
# ExitWorktree action: keep

# Artefatos vão pra vault/_agent/reports/
# Dashboard atualizado
```

---

## 📋 Checklist de Qualidade

Antes de sair do worktree, verificar:

- [ ] Branch tem commits bem documentados
- [ ] `vault/worktrees/<name>/README.md` — contexto completo
- [ ] `vault/worktrees/<name>/changes.md` — diff summarizado
- [ ] `vault/worktrees/<name>/proposal.md` — pitch pra merge
- [ ] Tests rodaram (se aplicável)
- [ ] Sem conflicts com main
- [ ] Link no kanban aponta pro resultado

---

## 🎨 Dashboard de Exemplo

```markdown
## Status Geral

| Nome | Objetivo | Branch | Status | Entrada |
|------|----------|--------|--------|---------|
| propositor-bootstrap | Reduzir loops | propositor/bootstrap-sp | 🟢 In Progress | 2026-03-14 14:22 |
| fix-typo | Fix typo CLAUDE.md | fix/typo-claude-md | 🔵 Ready | 2026-03-14 12:10 |
| explorar-ia-local | Pesquisar LM Studio | explorar/ia-local-worktree | 🟡 Blocked | 2026-03-13 10:05 |

**Active:** 1 | **Ready:** 1 | **Blocked:** 1 | **Completed Today:** 3
```

---

## 🔮 Future

- [ ] Auto-cleanup worktrees >7 dias
- [ ] Metrics: avg time per worktree, success rate
- [ ] Slack notifications: "/worktree propositor-bootstrap is ready"
- [ ] Integration com CI/CD: rodar testes em worktree antes de merge
- [ ] Diff visualization inline no vault

