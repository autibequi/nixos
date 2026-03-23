---
scope: universal
audience: all agents, all sessions
updated: 2026-03-23T16:00Z
---

# Regras do Sistema Leech

> Leia este arquivo no inicio de qualquer ciclo ou sessao.
> Para detalhes de cada topico, consulte o arquivo listado abaixo — nao carregue tudo.

---

## As 10 Leis (resumo)

| # | Lei | Resumo |
|---|-----|--------|
| 1 | Self-Scheduling | Agente com clock DEVE ter card em tasks/AGENTS/ sempre |
| 2 | Memoria Antes | Atualizar memory.md ANTES de reagendar |
| 3 | Timestamps UTC | Todos os timestamps em UTC, formato YYYYMMDD_HH_MM |
| 4 | Kanban Forward | Cards so andam para frente: TODO→DOING→DONE |
| 5 | Territorialidade | Cada agente escreve apenas no seu territorio |
| 6 | Sem Commits | Nunca git commit/push sem CTO pedir |
| 7 | Quota Aware | >= 85% sonnet pausa, >= 95% todos encerram |
| 8 | Canais Oficiais | Comunicar via feed.md, ALERTA_, dashboard — nao criar arquivos soltos |
| 9 | Formato Cards | Nome: YYYYMMDD_HH_MM_<nome>.md + frontmatter model/timeout/agent + #stepsN |
| 10 | Workshop | workshop/<nome>/ e soberano — nao invadir o de outro |

---

## Mapa de Regras por Topico

| Topico | Arquivo |
|--------|---------|
| Leis completas + violacoes + penalidades | `self/skills/meta/rules/laws.md` |
| Protocolo de ciclo (inicio, fim, bedroom, reagendar) | `self/skills/meta/rules/agentroom.md` |
| Territorios de escrita por agente | `self/skills/meta/rules/laws.md#lei-5` |
| Scheduling de agentes + tasks one-off | `self/skills/meta/rules/scheduling.md` |
| Estrutura de diretorios do vault | `self/skills/meta/rules/map.md` |
| Regras por espaco (workshop/bedrooms/inbox/vault/trash/tasks) | `self/skills/meta/rules/spaces.md` |
| Perfil rapido dos agentes (modelo, clock, funcao) | `self/skills/meta/rules/agents.md` |
| TTL de done/ e arquivamento → vault/archive/ | `self/skills/meta/rules/spaces.md#done` |
| Implementacao via worktree (todos os agentes) | `self/skills/meta/rules/worktrees.md` |

---

> Para editar ou consultar via CLI: `/meta:rules`
