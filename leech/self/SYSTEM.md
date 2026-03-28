---
name: SYSTEM
description: Paths do container, CLI, estrutura do vault Obsidian, agentes, logs
type: reference
updated: 2026-03-28
---

# System — Ambiente do Container

Você está dentro de um container gerenciado pelo **vennon**. Orquestração via **yaa** (sessões/agentes) e **deck** (TUI/host).

## Paths

| Path | O que é | Permissão |
|------|---------|-----------|
| `/workspace/self/` | Engine — skills, hooks, agents, scripts | rw |
| `/workspace/obsidian/` | Vault Obsidian — DASHBOARD, bedrooms, tasks, wiki, workshop | rw |
| `/workspace/home/` | Home do host ($HOME completo) | rw |
| `/workspace/host/` | Repo leech (~/leech) — bash, docker, rust, self | rw |
| `/workspace/projects/` | Projetos (~/projects) | rw |
| `/workspace/logs/host/` | Logs do sistema host (/var/log) | ro |
| `/workspace/logs/docker/` | Logs dos containers de serviço | ro |

**Working dir:** resolvido via `cd` no exec. Ex: `yaa ~/projects/app` → `cd /workspace/home/projects/app`.

## CLI (rodam no HOST, não no container)

| Comando | O que faz |
|---------|-----------|
| `yaa .` | Nova sessão claude no dir atual |
| `yaa --engine=cursor .` | Sessão com cursor |
| `yaa shell` | Zsh interativo no container |
| `yaa continue` | Continua última sessão |
| `yaa phone <agent>` | Chama um agente |
| `yaa tick` | Roda ciclo de agentes |
| `yaa usage claude` | Mostra quota |
| `vennon list` | Lista containers disponíveis |
| `vennon monolito serve` | Levanta serviço |
| `deck` | TUI dashboard |
| `deck stow` | Deploy dotfiles |
| `deck os switch` | NixOS rebuild |

## Obsidian Vault (`/workspace/obsidian/`)

| Path | Conteúdo |
|------|----------|
| `DASHBOARD.md` | Estado dos agentes (WORKING/DONE/BLOCKED/SLEEPING/SCHEDULE) |
| `bedrooms/<agent>/` | Memória persistente — memory.md, done/, diario.md |
| `tasks/{TODO,DOING,DONE}/` | Kanban de tarefas (.md cards) |
| `inbox/` | Mensagens recebidas (feed.md, alertas, cartas) |
| `outbox/` | Mensagens do user para agentes |
| `wiki/` | Knowledge base (estrategia/, leech/, host/, pedrinho/) |
| `workshop/` | Projetos ativos |

## Agents (`/workspace/self/agents/`)

Cada `agent.md` tem frontmatter: `model`, `clock`, `max_turns`.
Hermes dispatcha via DASHBOARD.md. `yaa phone <agent>` para chamar direto.

Ver lista atualizada em `self/memory/project_obsidian_agents.md`.

## Glossário

| Termo | Significado |
|-------|-------------|
| `leech` | CLI principal (Rust). `self/` = docs/skills/hooks do sistema |
| `yaa` | Wrapper CLI para sessões e agentes |
| `vennon` | Orquestrador de containers |
| `deck` | TUI dashboard no host |
| `bedroom` | Pasta privada de cada agente no vault |
| `workshop` | Projetos colaborativos no vault |
| `tick` | Ciclo de agentes despachado pelo Hermes |

## Logs de Containers (`/workspace/logs/docker/`)

Plataforma Estratégia — logs de runtime:
- `monolito/service.log` — Go backend API (porta 4004)
- `bo-container/service.log` — Vue/Quasar admin (porta 9090)
- `front-student/service.log` — Nuxt student frontend (porta 3005)
