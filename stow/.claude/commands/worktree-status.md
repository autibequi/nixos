---
name: /worktree-status
description: Mostra status detalhado do worktree atual (ou lista todos se nenhum ativo)
category: infrastructure
tags: #worktrees #gestao #infraestrutura
---

# /worktree-status

Exibe informações do worktree isolado em que você tá trabalhando — branch, mudanças, estado de proposta, tudo num relance.

## Uso

```
/worktree-status          # Status detalhado do worktree atual
/worktree-status --list   # Lista todos os worktrees conhecidos
/worktree-status --clean  # Remove worktrees antigos (>7 dias)
```

## O que mostra

```
🔀 WORKTREE: propositor-bootstrap-single-pass

├─ Branch: propositor/bootstrap-single-pass
├─ Entrado: 2026-03-14 14:22:03
├─ Tempo: 2h 47min
├─ Status: Em progresso
│
├─ 📝 Changes:
│  ├─ M  bootstrap.sh (42 linhas)
│  ├─ M  makefile (3 linhas)
│  └─ Total: 2 arquivos, 45 alterações
│
├─ 🎯 Proposta:
│  └─ [[worktrees/propositor-bootstrap-single-pass/proposal|Reduzir loops bootstrap: 5→1]]
│
└─ 📂 Artefatos:
   ├─ vault/worktrees/propositor-bootstrap-single-pass/README.md
   ├─ vault/worktrees/propositor-bootstrap-single-pass/changes.md
   └─ vault/worktrees/propositor-bootstrap-single-pass/proposal.md
```

## Integração com kanban

O worktree é linkado no card do kanban:
- Quando entro: atualizar `vault/worktrees.md` com novo card
- Quando saio: mover pra `vault/_agent/reports/` e marcar como concluído

## Fluxo

1. User pede trabalho com `#worktree`
2. `EnterWorktree` cria branch isolada + worktree
3. `/worktree-status` mostra progresso
4. Quando termina: `ExitWorktree` com `action: keep/remove`
5. Card kanban aponta pro resultado final

