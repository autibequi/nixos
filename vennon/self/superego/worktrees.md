# Worktrees — Isolamento para Implementacao

> Agentes usam worktrees para implementacoes isoladas.
> Sempre perguntar ao CTO se prefere worktree ou editar diretamente.
> Nunca assumir automaticamente.

---

## Criacao

```bash
vennon wt new <agente>/<task-kebab>
# ex: vennon wt new coruja/metrics-dashboard
# ex: vennon wt new gandalf/FUK2-12345-auth-fix
```

Branch = nome da tarefa. Se tem card Jira: usar o ID. Se nao: kebab-case descritivo.

## Fluxo obrigatorio

```
1. Criar:       vennon wt new <agente>/<task>
2. Implementar: repos em /workspace/home/worktree/<sessao>/
3. Apresentar:  criar inbox/WORKTREE_<agente>_<nome>_<YYYYMMDD>.md
4. CTO revisa:  vennon wt <agente>/<task>
5. CTO aprova:  vennon wt <agente>/<task> --close
```

## Card de apresentacao (obrigatorio)

Criar `inbox/WORKTREE_<agente>_<nome>_<YYYYMMDD>.md`:

```markdown
---
tipo: worktree-proposta
agent: <nome>
sessao: <agente>/<task>
status: pendente-review
criado: YYYY-MM-DDThh:mmZ
---

# [Proposta] <titulo curto>

**Repos afetados:** monolito, bo-container (listar quais)

## O que foi feito
<descricao>

## Por que
<motivacao e impacto>

## Como revisar
vennon wt <agente>/<task>

## Como aprovar
vennon wt <agente>/<task> --close
```

## Limites

- Maximo 3 sessoes pendentes por agente — se atingido, nao criar novos ate CTO revisar
- Agentes NUNCA fazem `git commit` ou `git push` — apenas criam worktree e apresentam
- CTO lista sessoes: `vennon wt` ou `vennon worktree`

## Quem pode usar

Agentes que implementam: gandalf, mechanic, coruja.
Agentes de leitura (assistant, paperboy, tamagochi, wanderer): nao precisam.
