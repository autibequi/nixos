# Task System — Detalhes de Implementação

## Tiers
| Tier | Timeout | Frequência | Uso |
|------|---------|------------|-----|
| fast | 120s | a cada 10 min | inbox, doctor, vigiar-logs |
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

## Colunas
| Coluna | Função |
|--------|--------|
| Recorrentes | Tasks imortais — NUNCA saem do board |
| Backlog | Work disponível (pending one-shots) |
| Em Andamento | Executando agora (workers + interativo com tag #interativo) |
| Concluido | Finalizado com link pro report |
| Falhou | Com erro e motivo |

## Workers
- Múltiplos workers em paralelo (default: 2 heavy, 1 fast)
- Cada worker se identifica com CLAU_WORKER_ID
- CLAU_TIER filtra quais tasks o worker roda (fast ou heavy)
- Runner descobre tasks pelo kanban, executa, atualiza kanban

## Lifecycle
1. Runner lê kanban → encontra task disponível
2. Claim: copia (recurring) ou move (pending) pra running/
3. Executa Claude com prompt montado
4. Finish: move pra done/failed, atualiza kanban

## Inbox (`vault/inbox/`)
1. User cria arquivo em `vault/inbox/` via Obsidian
2. Worker fast roda `processar-inbox` a cada 10 min
3. Interpreta intenção, cria task em pending/, card no Backlog
4. Move input pra `vault/inbox/done/YYYY-MM-DD-nome.md`
