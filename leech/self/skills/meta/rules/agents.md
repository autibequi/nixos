---
maintainer: wiseman
updated: 2026-03-23T16:00Z
---

# Agentes — Perfil Rapido

| Agente | Modelo | Clock | Funcao |
|--------|--------|-------|--------|
| assistant | haiku | every20 | Monitor proativo — repos sujos, PRs, hora avancada |
| coruja | sonnet | every60 | Full-stack Estrategia + segundo cerebro |
| hermes | haiku | every10 | Routing inbox/outbox + scheduling |
| jafar | sonnet | every120 | Introspecao + melhoria do sistema |
| keeper | haiku | every30 | Limpeza + saude do vault |
| mechanic | sonnet | on-demand | NixOS, dotfiles, containers |
| paperboy | haiku | every60 | RSS + digest |
| tamagochi | haiku | every10 | Pet virtual |
| tasker | sonnet | on-demand | Executa tasks do kanban |
| wanderer | sonnet | every60 | Exploracao + sintese cross-repo |
| wiseman | sonnet | every60 | Weave, audit, enforce, meta |

## Agentes On-Demand

Mechanic e tasker nao tem card permanente em `bedrooms/_waiting/`. So aparecem quando convocados via outbox.

## Delegacao — quem faz o que

| Tipo | Agente |
|------|--------|
| Saude, disco, limpeza | keeper |
| Arquivamento de done/ + limpeza | keeper |
| NixOS, dotfiles, seguranca | mechanic |
| Go/Vue/Nuxt, Jira, PRs | coruja |
| Explorar, sintetizar | wanderer |
| Grafo, weaving, meta | wiseman |
| RSS | paperboy |
| Inbox/outbox, routing | hermes |
| Introspecao, propostas | jafar |
| Monitor repos/PRs | assistant |
| Tasks genericas | tasker |
| Pet virtual | tamagochi |

## Detalhes

Perfis completos em `self/agents/<nome>/agent.md`.
