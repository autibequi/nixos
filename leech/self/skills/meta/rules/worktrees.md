---
maintainer: wiseman
updated: 2026-03-23T16:00Z
---

# Worktrees — Regra Universal de Implementacao

**Existem dois tipos de worktree no sistema. Use o correto para cada contexto.**

---

## Tipo 1 — Sessoes multi-repo do usuario (`leech wt`)

Para features da Estrategia que tocam multiplos repos. Gerenciado pelo CTO via CLI.

```bash
leech wt new FUK2-12345     # CTO cria
leech wt FUK2-12345         # CTO ativa/switch
leech wt main               # CTO volta pra main
```

Path: `/workspace/mnt/worktree/<sessao>/<repo>/`

**Agentes trabalham dentro dessas sessoes** — editar em
`/workspace/mnt/worktree/<sessao>/<repo>/` quando designados pelo CTO.
Para apresentar o trabalho: `leech wt <sessao-do-agente>` notifica o CTO via inbox.

Ver: `leech/worktree` skill para o fluxo completo.

---

## Tipo 2 — Propostas de agentes (`git worktree` manual)

**Todo agente que implementar mudancas em codigo ou configs DEVE usar worktree.**
Nunca editar diretamente na branch principal. Nunca commitar. Apresentar ao CTO no final.

---

## Fluxo obrigatorio

```
1. Criar worktree
2. Implementar no worktree
3. Criar inbox card apresentando a mudanca
4. Aguardar CTO revisar e commitar
5. CTO aprova → agente remove o worktree
```

## Criar worktree

```bash
cd <repo-raiz>
git worktree add /tmp/<agent>-<YYYYMMDD>-<nome> -b <agent>/<nome>
# ex: git worktree add /tmp/jafar-20260323-auth-fix -b jafar/auth-fix
```

**Convencoes de nome:**
- Branch: `<agent>/<descricao-kebab>`
- Diretorio: `/tmp/<agent>-<YYYYMMDD>-<nome>`

## Apresentar ao CTO (inbox card obrigatorio)

Criar `inbox/WORKTREE_<agent>_<nome>_<YYYYMMDD>.md`:

```markdown
---
tipo: worktree-proposta
agent: <nome>
branch: <agent>/<nome>
repo: <repo>
status: pendente-review
criado: YYYY-MM-DDThh:mmZ
---

# [Proposta] <titulo curto>

**Branch:** `<agent>/<nome>`
**Repo:** `<repo>`
**Worktree:** `/tmp/<agent>-<YYYYMMDD>-<nome>`

## O que foi feito

<descricao do que foi implementado>

## Por que

<motivacao e impacto esperado>

## Como revisar

\`\`\`bash
git diff main..<agent>/<nome>
# ou
cd /tmp/<agent>-<YYYYMMDD>-<nome> && git log --oneline
\`\`\`

## Como commitar (quando aprovado)

\`\`\`bash
cd <repo>
git merge <agent>/<nome>
git worktree remove /tmp/<agent>-<YYYYMMDD>-<nome>
git branch -d <agent>/<nome>
\`\`\`
```

## Limites

- Maximo **3 worktrees pendentes por agente** — se atingido, nao criar novos ate CTO revisar
- Worktrees em `/tmp/` sao efemeros — se o container reiniciar, o worktree some (a branch permanece)
- Agentes **NUNCA** fazem `git merge` ou `git commit` — apenas criam o worktree e apresentam

## Remover worktree (apos aprovacao do CTO)

```bash
git worktree remove /tmp/<agent>-<YYYYMMDD>-<nome>
git branch -d <agent>/<nome>
```

## Quem pode usar

Todos os agentes que implementam mudancas — jafar, mechanic, coruja, tasker, etc.
Agentes de leitura/monitoramento (assistant, paperboy, tamagochi, wanderer) nao precisam.
