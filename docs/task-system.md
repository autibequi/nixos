# Task System — Detalhes de Implementação

## Clocks
| Clock | Timeout | Frequência | Uso |
|-------|---------|------------|-----|
| every10 | 120s | a cada 10 min | processar-inbox, doctor, vigiar-logs |
| every60 | 180-600s | a cada hora | radar, avaliar, sumarizer, trashman, trashman-clean-assets |
| every240 | 300-600s | a cada 4 horas | evolucao, wiseman, propositor, guardinha |

## Frontmatter de tasks
```yaml
---
clock: every10|every60|every240
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
- Tasks com `worktrees: true` têm **liberdade total** dentro do worktree — podem editar código à vontade
- Ao terminar, o worker move o card pra coluna **"Esperando Review"** e o user decide aceitar/descartar

## Tags especiais
| Tag | Efeito |
|-----|--------|
| `#haiku` | Task designada para Haiku (rápida, simples) |
| `#sonnet` | Task designada para Sonnet (análise, síntese) |
| `#opus` | Task designada para Opus (complexo, design) |
| Sem tag modelo | `#auto` (worker decide baseado em contexto) |
| `#interativo` | Card de sessão interativa (não processado por workers) |

## Kanban — Formato de cards
- Card normal: `- [ ] **nome** #tag DATA \`modelo\` — descrição`
- Card concluído: `- [x] **nome** #done DATA \`modelo\` — [report](path)`
- Card em andamento: `- [ ] **nome** [worker-N] \`modelo\` — descrição`
- Card interativo: `- [ ] **nome** #interativo \`modelo\` — descrição`

## Arquivos
- `vault/kanban.md` — work items (Backlog, Inbox, Em Andamento, Esperando Review, Aprovado, Falhou)
- `vault/cemiterio-tasks.md` — tasks arquivadas/deprecated (Arquivado, Deprecated)
- `vault/scheduled.md` — tasks recorrentes (Recorrentes, Em Execução, Histórico)

## Colunas — kanban.md
| Coluna | Função |
|--------|--------|
| Backlog | Work disponível (pending one-shots, filtrado por clock) |
| Inbox | Pedidos do user em texto livre — processados por processar-inbox |
| Em Andamento | Executando agora (workers + interativo com tag #interativo) |
| Esperando Review | Task terminou e aguarda atenção do user (worktree pronto, proposta, etc) |
| Aprovado | Finalizado e aprovado pelo user (com link pro report) |
| Falhou | Com erro e motivo |

## Colunas — cemiterio-tasks.md
| Coluna | Função |
|--------|--------|
| Arquivado | Tasks concluídas movidas do Aprovado (limpeza periódica) |
| Deprecated | Tasks obsoletas/descartadas (tag `#deprecated`) |

## Colunas — scheduled.md
| Coluna | Função |
|--------|--------|
| Recorrentes | Tasks imortais — NUNCA saem do board |
| Em Execução | Cópia temporária durante execução do worker |
| Histórico | Log de execuções passadas (opcional) |

## Workers
- **Controle de custo parametrizável** via `local.agents.claudinho` (NixOS):
  - `maxConcurrentWorkers` (default 1): máximo de containers Claude rodando ao mesmo tempo no sistema. 1 = só um por vez; no futuro pode aumentar.
  - `maxWorkersFast` / `maxWorkersHeavy` / `maxWorkersSlow` (default 1 cada): máximo que cada timer (every10, every60, every240) pode levantar por execução — evita fast/heavy levantarem “10” de uma vez.
- Com `maxConcurrentWorkers = 1`: lock global, apenas um runner por vez; com valor > 1: vários runners podem rodar em paralelo respeitando o limite total.
- Cada worker se identifica com CLAU_WORKER_ID
- CLAU_CLOCK filtra quais tasks o worker roda (every10, every60 ou every240)
- Runner lê recorrentes de scheduled.md, backlog de kanban.md
- Todos os clocks processam backlog (filtrado por clock da task)

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
