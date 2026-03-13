# Task System — Detalhes de Implementação

## Tiers
| Tier | Timeout | Frequência | Uso |
|------|---------|------------|-----|
| fast | 120s | a cada 10 min | processar-inbox, doctor, vigiar-logs |
| heavy | 300-600s | hourly | radar, avaliar, evolucao |

## Frontmatter de tasks
```yaml
---
tier: fast|heavy
timeout: 120
model: haiku|sonnet
schedule: always|night
mcp: true|false
max_turns: 25
---
```

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
| Backlog | Work disponível (pending one-shots, filtrado por tier) |
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
- Múltiplos workers em paralelo (default: 2 heavy, 1 fast)
- Cada worker se identifica com CLAU_WORKER_ID
- CLAU_TIER filtra quais tasks o worker roda (fast ou heavy)
- Runner lê recorrentes de scheduled.md, backlog de kanban.md
- Ambos os tiers processam backlog (filtrado por tier da task)

## Lifecycle
1. Runner lê scheduled.md (recorrentes) + kanban.md (backlog) → encontra task disponível
2. Claim: copia (recurring→Em Execução em scheduled) ou move (pending→Em Andamento em kanban)
3. Executa Claude com prompt montado
4. Finish: move pra done/failed, atualiza kanban/scheduled

## Inbox (coluna do kanban)
1. User adiciona card na coluna "Inbox" do kanban via Obsidian (texto livre)
2. Worker fast roda `processar-inbox` a cada 10 min
3. Interpreta intenção, cria task em pending/, card formatado no Backlog
4. Remove card original da coluna Inbox
