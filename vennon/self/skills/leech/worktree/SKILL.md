---
name: leech/worktree
description: Sistema unificado de worktrees — leech wt. Cria, troca e gerencia sessoes de branches sincronizadas em todos os repos da Estrategia. Usado por CTO e agentes.
---

# Skill: leech/worktree

Gerencia sessoes de trabalho multi-repo via `leech wt`. Cada sessao representa
uma tarefa com branches checadas em paralelo em todos os repos relevantes.
Permite trocar de sessao instantaneamente com stash automatico.

**Padrão recomendado:** worktree para features grandes ou multi-repo. Para fixes simples, perguntar ao user se prefere isolamento. Branch sempre tem o nome da tarefa quando usado.

---

## Interface

```bash
leech wt                        # lista sessoes (★ = ativa)
leech wt list                   # mesmo que acima
leech wt new <nome>             # cria sessao (pede confirmacao)
leech wt <nome>                 # switch para sessao (stash auto)
leech wt main                   # volta para main
leech wt <nome> --close         # deleta sessao
leech wt <nome> --force         # deleta sem confirmacao
leech worktree                  # lista worktrees por servico
leech worktree monolito         # filtra por servico
leech worktree --json           # saida JSON
```

---

## Estrutura no disco

```
/workspace/mnt/worktree/
├── .active                      <- sessao ativa atual ("main" ou "<nome>")
└── <nome>/
    ├── monolito/                <- branch <nome> do monolito
    ├── bo-container/            <- branch <nome> do bo-container
    ├── front-student/           <- branch <nome> do front-student
    └── toggler/                 <- (e todos os outros repos em estrategia/)
```

Repos descobertos automaticamente: todos com `.git` em `/workspace/mnt/estrategia/`.

---

## Naming — branch SEMPRE e o nome da tarefa

**Convencao obrigatoria:**
- CTO: `leech wt new FUK2-12345` → branch `FUK2-12345` em todos os repos
- Agentes: `leech wt new <agent>/<task-kebab>` → branch `<agent>/<task-kebab>`

Exemplos:
```bash
leech wt new FUK2-12345                     # CTO: feature card
leech wt new gandalf/FUK2-12345-auth-fix    # Gandalf: proposta
leech wt new coruja/metrics-dashboard       # Coruja: investigacao
leech wt new mechanic/nixos-waybar-fix      # Mechanic: fix de sistema
```

**Nunca criar branch sem nome de tarefa.** Se nao tem card Jira, usar descricao kebab-case.

---

## Criar sessao

```bash
leech wt new gandalf/auth-refactor
```

Mostra preview:
```
  monolito      branch nova  (base: HEAD)
  bo-container  branch existe (origin/gandalf/auth-refactor)
  front-student branch nova  (base: HEAD)

Confirmar? [s/N]
```

- Branch local existente → usa ela
- Branch remota existente → checkout com tracking
- Branch inexistente → cria nova a partir de HEAD

---

## Switch de sessao

```bash
leech wt gandalf/auth-refactor
```

Fluxo automatico:
1. Stash de arquivos pendentes na sessao atual (tag: `leech-wt-<sessao>`)
2. Atualiza `/workspace/mnt/worktree/.active`
3. Restaura stash da sessao alvo (se existir)

---

## Sessao main

`leech wt main` nao tem diretorio fisico — aponta para os repos principais
em `/workspace/mnt/estrategia/`. Stash da sessao atual e salvo antes de sair.

---

## Fluxo do CTO — Feature multi-repo

```bash
# 1. Criar sessao
leech wt new FUK2-12345

# 2. Ativar
leech wt FUK2-12345

# 3. Trabalhar em cada repo
#    /workspace/mnt/worktree/FUK2-12345/monolito/
#    /workspace/mnt/worktree/FUK2-12345/bo-container/

# 4. Testar
leech runner monolito start --worktree=FUK2-12345

# 5. Commit/push em cada repo

# 6. Voltar pra main
leech wt main

# 7. Limpar quando merged
leech wt FUK2-12345 --close
```

---

## Fluxo do Agente — Proposta via worktree

```bash
# 1. Agente cria sessao com nome da tarefa
leech wt new gandalf/FUK2-12345-auth-fix

# 2. Agente implementa em qualquer repo da sessao
#    /workspace/mnt/worktree/gandalf-FUK2-12345-auth-fix/monolito/
#    /workspace/mnt/worktree/gandalf-FUK2-12345-auth-fix/bo-container/

# 3. Agente apresenta ao CTO via inbox card WORKTREE_*
#    (formato em meta/rules/worktrees.md)

# 4. CTO revisa
leech wt gandalf/FUK2-12345-auth-fix

# 5. CTO aprova, fecha
leech wt gandalf/FUK2-12345-auth-fix --close
```

**Cada agente pode trabalhar em qualquer repo** dentro da sua sessao. Nao ha limitacao
de 1 repo por worktree — a sessao cobre todos os repos automaticamente.

---

## Regras

- **Branch = nome da tarefa** — sempre, sem excecao
- Agentes nunca commitam sem CTO pedir (Lei 6)
- Maximo 3 sessoes pendentes por agente
- Agentes apresentam via inbox card `WORKTREE_<agent>_<nome>_<YYYYMMDD>.md`
- CTO pode revisar com `leech wt <sessao-do-agente>`
- Regras completas: `meta/rules/worktrees.md`

---

## Integrar com leech runner

Apos criar sessao, o runner sabe usar os worktrees:

```bash
leech runner monolito start \
  --worktree=gandalf/auth-refactor
```

O `--worktree` resolve automaticamente para
`/workspace/mnt/worktree/gandalf-auth-refactor/monolito/`.
