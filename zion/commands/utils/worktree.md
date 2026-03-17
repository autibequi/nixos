---
name: /worktree
description: Dashboard de worktrees - status atual + histórico de workers
category: infrastructure
tags: #worktrees #gestao #infraestrutura
---

# /worktree

Dashboard unificado de worktrees isolados. Mostra:
- **Status atual** (se você está em um worktree agora)
- **Histórico de workers** (quando cada worker lançou worktrees)
- **Rastreamento automático** (cada worker lançamento é registrado)

## Uso

```
/worktree              # Status atual + histórico recente
/worktree --full       # Histórico completo de todos os workers
/worktree --workers    # Timeline de quando cada worker rodou worktrees
/worktree --list       # Lista todos os worktrees conhecidos
```

## Output: Status Atual + Histórico de Workers

```
🔀 WORKTREE — Dashboard

┌─ Status Atual ─────────────────────────────┐
│ Você está em: propositor-bootstrap        │
│ Branch: propositor/bootstrap-single-pass  │
│ Entrado: 2026-03-14 14:22:03 (2h 47min)  │
│ Mudanças: 2 arquivos, +45 -18 linhas     │
└────────────────────────────────────────────┘

┌─ Histórico: Workers Lançaram Worktrees ─┐
│                                          │
│ 2026-03-14 14:22 | worker-every60-1     │
│ ├─ propositor-bootstrap                 │
│ ├─ Duration: 1h 45min → concluído       │
│ └─ Artefatos: [[obsidian/worktrees/...]]  │
│                                          │
│ 2026-03-14 12:10 | worker-every10-1     │
│ ├─ fix-typo                             │
│ ├─ Duration: 18min → em progresso       │
│ └─ Artefatos: [[obsidian/worktrees/...]]  │
│                                          │
└──────────────────────────────────────────┘
```

## Auto-Tracking: Como Funciona

1. **Worker lança worktree** → `/worktree init` registra automaticamente
2. **Enquanto roda** → `/worktree` mostra progresso
3. **Quando termina** → `/worktree exit` finaliza e move pra reports
4. **Histórico** → Tudo fica em `.worktrees-registry.json` + log

Log permanente: `obsidian/.worktrees-log.jsonl` (append-only)
- Cada linha = um evento de worktree (enter/exit/update)
- Compartilhado entre todos os workers

## Integração com Workers

- **every10 worker** — Lança worktrees simples (inbox processing)
- **every60 worker** — Lança worktrees pesados (proposals, análises)
- **Ambos compartilham** → Mesmo dashboard, visibilidade completa

Quando ambos rodando, `/worktree` mostra timeline paralela.

