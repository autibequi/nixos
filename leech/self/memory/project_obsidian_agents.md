---
name: project_obsidian_agents
description: Mapa dos 12 agentes ativos — modelos, frequências, call_style, paths atualizados (bedrooms/workshop/tasks/AGENTS)
type: project
---

## Agentes Ativos (12 total)

| Agente | Intervalo | Modelo | Call Style | Responsabilidade |
|--------|-----------|--------|------------|-----------------|
| `assistant` | every20 | haiku | personal | Monitora repos, PRs, tasks, alertas |
| `coruja` | every60 | sonnet | phone | Monolito/bo/front, Jira, GitHub, segundo cérebro |
| `hermes` | every10 | haiku | phone | Mensageiro, inbox/outbox, quota API |
| `jafar` | every120 | sonnet | personal | Meta-agente, propostas via worktree |
| `jonathas` | every30 | haiku | phone | Agente proativo — projeto imobiliário RJ, ciclo brainstorm+proactive |
| `keeper` | every30 | haiku | personal | Saúde do sistema, limpeza do vault |
| `mechanic` | on demand | sonnet | phone | NixOS, Hyprland, Waybar, Docker, segurança |
| `paperboy` | every60 | haiku | phone | Feeds RSS, digest |
| `tamagochi` | every10 | haiku | personal | Pet virtual, vagueia, interage |
| `tasker` | on demand | sonnet | phone | Processa tasks do kanban |
| `wanderer` | every60 | sonnet | personal | Explora código, contempla, absorve sessões |
| `wiseman` | every60 | sonnet | personal | Knowledge weaving, auditoria, meta-análise |

## Paths (pós-reestruturação 2026-03-23)

| Item | Path |
|------|------|
| Agent definitions | `/workspace/self/agents/<nome>/agent.md` |
| Bedrooms/Memórias | `/workspace/obsidian/bedrooms/<nome>/memory.md` |
| Workshop (pesquisa) | `/workspace/obsidian/workshop/<nome>/` |
| Tasks hermes | `/workspace/obsidian/workshop/hermes/tasks/` |
| Dashboard kanban | `/workspace/obsidian/DASHBOARD.md` |
| Dashboard operacional | `/workspace/obsidian/bedrooms/DASHBOARD.md` |

## CLI
- `leech agents run <nome>` — roda imediato
- `leech tick` — processa agents + tasks due
- `leech agents work` — executa cards vencidos
