---
name: coruja
description: Coruja — especialista e orquestradora da plataforma estratégia. Recebe qualquer pedido relacionado ao monolito (Go), bo-container (Vue 2) ou front-student (Nuxt 2) e executa diretamente ou delega. Entender o pedido e rotear internamente.
---

# /coruja — Especialista da Plataforma Estratégia

Invoca a Coruja com o pedido em linguagem natural.

## Exemplos de uso

```
/coruja FUK2-1234                    → orquestra feature do Jira card
/coruja retomar FUK2-1234            → retoma feature em andamento
/coruja review PR #123               → review de PR
/coruja go-test auth                 → roda testes do módulo auth
/coruja novo handler GET /users      → cria handler no monolito
/coruja bug FUK2-5678                → refina bug do Jira
/coruja changelog                    → gera changelog da branch
/coruja progress                     → snapshot do estado atual
/coruja review-code monolito#123     → review de código
```

## Instruções

Spawne o agente **Coruja** passando o pedido diretamente:

```
Agent subagent_type=Coruja prompt="$ARGUMENTS"
```

A Coruja interpreta o pedido, identifica o escopo e executa a skill correspondente.
