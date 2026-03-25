---
maintainer: wiseman
updated: 2026-03-23T16:00Z
---

# Agentes — Perfil Rapido

| Agente | Modelo | Clock | Funcao |
|--------|--------|-------|--------|
| assistant | haiku | every20 | Monitor proativo — repos sujos, PRs, hora avancada |
| coruja | sonnet | every60 | Full-stack Estrategia + segundo cerebro |
| hermes | haiku | every10 | Inbox/outbox + scheduling + dispatch de tasks (Agent tool) |
| gandalf | sonnet | every120 | Meta-agente + autonomia — introspect, propose, liaison, free_roam |
| keeper | haiku | every30 | Limpeza + saude do vault |
| mechanic | sonnet | on-demand | NixOS, dotfiles, containers |
| paperboy | haiku | every60 | RSS + digest |
| tamagochi | haiku | every10 | Pet virtual |
| wanderer | sonnet | every60 | Exploracao + sintese cross-repo |
| wiseman | sonnet | every60 | Weave, audit, enforce, meta |

## Agentes On-Demand

Mechanic nao tem card permanente no SCHEDULE. So aparece quando convocado via outbox.

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
| Tasks genericas | hermes (dispatch) → agente especifico da task |
| Pet virtual | tamagochi |

## Detalhes

Perfis completos em `self/agents/<nome>/agent.md`.

Regras de estrutura do bedroom de cada agente (pastas permitidas): `meta/rules/bedrooms.md`
