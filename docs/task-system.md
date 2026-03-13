# Task System — Detalhes de Implementação

## Clocks
| Clock | Timeout | Frequência | Uso |
|-------|---------|------------|-----|
| every10 | 120s | a cada 10 min | processar-inbox, doctor, vigiar-logs |
| every60 | 300-600s | a cada hora | radar, avaliar, evolucao |

## Frontmatter de tasks
```yaml
---
clock: every10|every60
timeout: 120
model: haiku|sonnet
schedule: always|night
mcp: true|false
worktrees: true|false
max_turns: 25
---
```

## Permissão de Worktrees
- `worktrees: true` no frontmatter = task pode usar `EnterWorktree`/`ExitWorktree`
- Sem esse campo ou `worktrees: false` = worktree PROIBIDO
- Sessões interativas (`/propor`) sempre podem — o user pediu explicitamente

## Tags especiais
| Tag | Efeito |
|-----|--------|
| `#interativo` | Card de sessão interativa (não processado por workers) |

## Kanban — Formato de cards
- Card normal: `- [ ] **nome** #tag DATA \`modelo\` — descrição`
- Card concluído: `- [x] **nome** #done DATA \`modelo\` — [report](path)`
- Card em andamento: `- [ ] **nome** [worker-N] \`modelo\` — descrição`
- Card interativo: `- [ ] **nome** #interativo \`modelo\` — descrição`

## Arquivos
- `vault/kanban.md` — work items (Backlog, Inbox, Em Andamento, Concluido, Falhou)
- `vault/scheduled.md` — tasks recorrentes (Recorrentes, Em Execução, Histórico)

## Colunas — kanban.md
| Coluna | Função |
|--------|--------|
| Backlog | Work disponível (pending one-shots, filtrado por clock) |
| Inbox | Pedidos do user em texto livre — processados por processar-inbox |
| Em Andamento | Executando agora (workers + interativo com tag #interativo) |
| Concluido | Finalizado com link pro report |
| Falhou | Com erro e motivo |

## Colunas — scheduled.md
| Coluna | Função |
|--------|--------|
| Recorrentes | Tasks imortais — NUNCA saem do board |
| Em Execução | Cópia temporária durante execução do worker |
| Histórico | Log de execuções passadas (opcional) |

## Workers
- Múltiplos workers em paralelo (default: 2 every60, 1 every10)
- Cada worker se identifica com CLAU_WORKER_ID
- CLAU_CLOCK filtra quais tasks o worker roda (every10 ou every60)
- Runner lê recorrentes de scheduled.md, backlog de kanban.md
- Ambos os clocks processam backlog (filtrado por clock da task)

## Lifecycle
1. Runner lê scheduled.md (recorrentes) + kanban.md (backlog) → encontra task disponível
2. Claim: copia (recurring→Em Execução em scheduled) ou move (pending→Em Andamento em kanban)
3. Executa Claude com prompt montado
4. Finish: move pra done/failed, atualiza kanban/scheduled

## Inbox (coluna do kanban)
1. User adiciona card na coluna "Inbox" do kanban via Obsidian (texto livre)
2. Worker every10 roda `processar-inbox` a cada 10 min
3. Interpreta intenção, cria task em pending/, card formatado no Backlog
4. Remove card original da coluna Inbox
