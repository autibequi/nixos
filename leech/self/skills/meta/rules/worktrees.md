---
maintainer: wiseman
updated: 2026-03-24T22:00Z
---

# Worktrees — Regra Universal de Implementacao

**Todo agente que implementar mudancas DEVE usar worktree via `leech wt`.**
Nunca editar diretamente na branch principal. Nunca commitar. Apresentar ao CTO.

---

## Naming — branch e o nome da tarefa

```bash
leech wt new <agent>/<task-kebab>
```

Exemplos:
- `leech wt new gandalf/FUK2-12345-auth-fix`
- `leech wt new coruja/metrics-dashboard`
- `leech wt new mechanic/waybar-animation-fix`

**Branch = nome da tarefa, sempre.** Se tem card Jira: usar o ID. Se nao: kebab-case descritivo.

---

## Fluxo obrigatorio

```
1. Criar sessao:    leech wt new <agent>/<task>
2. Implementar:     nos repos dentro de /workspace/mnt/worktree/<sessao>/
3. Apresentar:      inbox card WORKTREE_<agent>_<nome>_<YYYYMMDD>.md
4. CTO revisa:      leech wt <agent>/<task>
5. CTO aprova:      leech wt <agent>/<task> --close
```

---

## Criar sessao

```bash
leech wt new gandalf/auth-refactor
```

Cria branch `gandalf/auth-refactor` em todos os repos (monolito, bo-container, front-student, etc.).

Path no disco:
```
/workspace/mnt/worktree/gandalf-auth-refactor/
├── monolito/
├── bo-container/
├── front-student/
└── ...
```

Cada agente pode trabalhar em **qualquer repo** da sessao — nao ha limitacao de 1 repo.

---

## Apresentar ao CTO (inbox card obrigatorio)

Criar `inbox/WORKTREE_<agent>_<nome>_<YYYYMMDD>.md`:

```markdown
---
tipo: worktree-proposta
agent: <nome>
sessao: <agent>/<task>
status: pendente-review
criado: YYYY-MM-DDThh:mmZ
---

# [Proposta] <titulo curto>

**Sessao:** `<agent>/<task>`
**Repos afetados:** monolito, bo-container (listar quais)

## O que foi feito

<descricao do que foi implementado>

## Por que

<motivacao e impacto esperado>

## Como revisar

\`\`\`bash
leech wt <agent>/<task>
# CTO entra no worktree e pode testar direto
\`\`\`

## Como aprovar

\`\`\`bash
# Commit/push em cada repo afetado
leech wt <agent>/<task> --close
\`\`\`
```

---

## Limites

- Maximo **3 sessoes pendentes por agente** — se atingido, nao criar novos ate CTO revisar
- Agentes **NUNCA** fazem `git commit` ou `git push` — apenas criam worktree e apresentam
- CTO pode listar todas as sessoes: `leech wt` ou `leech worktree`

---

## Quem pode usar

Todos os agentes que implementam mudancas — gandalf, mechanic, coruja, etc.
Agentes de leitura/monitoramento (assistant, paperboy, tamagochi, wanderer) nao precisam.

---

## Referencia

Skill completo com interface CLI: `leech/worktree` (`self/skills/leech/worktree/SKILL.md`)
