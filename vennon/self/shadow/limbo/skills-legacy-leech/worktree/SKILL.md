---
name: vennon/worktree
description: Sistema unificado de worktrees — vennon wt. Cria, troca e gerencia sessoes de branches sincronizadas em todos os repos da Estrategia. Usado por CTO e agentes.
---

# Skill: vennon/worktree

Gerencia sessoes de trabalho multi-repo via `vennon wt`. Cada sessao representa
uma tarefa com branches checadas em paralelo em todos os repos relevantes.
Permite trocar de sessao instantaneamente com stash automatico.

**Padrão recomendado:** worktree para features grandes ou multi-repo. Para fixes simples, perguntar ao user se prefere isolamento. Branch sempre tem o nome da tarefa quando usado.

---

## Interface

```bash
vennon wt                        # lista sessoes (★ = ativa)
vennon wt list                   # mesmo que acima
vennon wt new <nome>             # cria sessao (pede confirmacao)
vennon wt <nome>                 # switch para sessao (stash auto)
vennon wt main                   # volta para main
vennon wt <nome> --close         # deleta sessao
vennon wt <nome> --force         # deleta sem confirmacao
vennon worktree                  # lista worktrees por servico
vennon worktree monolito         # filtra por servico
vennon worktree --json           # saida JSON
```

---

## Estrutura no disco

```
/workspace/home/worktree/
├── .active                      <- sessao ativa atual ("main" ou "<nome>")
└── <nome>/
    ├── monolito/                <- branch <nome> do monolito
    ├── bo-container/            <- branch <nome> do bo-container
    ├── front-student/           <- branch <nome> do front-student
    └── toggler/                 <- (e todos os outros repos em estrategia/)
```

Repos descobertos automaticamente: todos com `.git` em `/workspace/home/estrategia/`.

---

## Naming — branch SEMPRE e o nome da tarefa

**Convencao obrigatoria:**
- CTO: `vennon wt new FUK2-12345` → branch `FUK2-12345` em todos os repos
- Agentes: `vennon wt new <agent>/<task-kebab>` → branch `<agent>/<task-kebab>`

Exemplos:
```bash
vennon wt new FUK2-12345                     # CTO: feature card
vennon wt new gandalf/FUK2-12345-auth-fix    # Gandalf: proposta
vennon wt new coruja/metrics-dashboard       # Coruja: investigacao
vennon wt new mechanic/nixos-waybar-fix      # Mechanic: fix de sistema
```

**Nunca criar branch sem nome de tarefa.** Se nao tem card Jira, usar descricao kebab-case.

---

## Criar sessao

```bash
vennon wt new gandalf/auth-refactor
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
vennon wt gandalf/auth-refactor
```

Fluxo automatico:
1. Stash de arquivos pendentes na sessao atual (tag: `vennon-wt-<sessao>`)
2. Atualiza `/workspace/home/worktree/.active`
3. Restaura stash da sessao alvo (se existir)

---

## Sessao main

`vennon wt main` nao tem diretorio fisico — aponta para os repos principais
em `/workspace/home/estrategia/`. Stash da sessao atual e salvo antes de sair.

---

## Fluxo do CTO — Feature multi-repo

```bash
# 1. Criar sessao
vennon wt new FUK2-12345

# 2. Ativar
vennon wt FUK2-12345

# 3. Trabalhar em cada repo
#    /workspace/home/worktree/FUK2-12345/monolito/
#    /workspace/home/worktree/FUK2-12345/bo-container/

# 4. Testar
vennon monolito start --worktree=FUK2-12345

# 5. Commit/push em cada repo

# 6. Voltar pra main
vennon wt main

# 7. Limpar quando merged
vennon wt FUK2-12345 --close
```

---

## Fluxo do Agente — Proposta via worktree

```bash
# 1. Agente cria sessao com nome da tarefa
vennon wt new gandalf/FUK2-12345-auth-fix

# 2. Agente implementa em qualquer repo da sessao
#    /workspace/home/worktree/gandalf-FUK2-12345-auth-fix/monolito/
#    /workspace/home/worktree/gandalf-FUK2-12345-auth-fix/bo-container/

# 3. Agente apresenta ao CTO via inbox card WORKTREE_*
#    (formato em self/superego/worktrees.md)

# 4. CTO revisa
vennon wt gandalf/FUK2-12345-auth-fix

# 5. CTO aprova, fecha
vennon wt gandalf/FUK2-12345-auth-fix --close
```

**Cada agente pode trabalhar em qualquer repo** dentro da sua sessao. Nao ha limitacao
de 1 repo por worktree — a sessao cobre todos os repos automaticamente.

---

## Regras

- **Branch = nome da tarefa** — sempre, sem excecao
- Agentes nunca commitam sem CTO pedir (Lei 6)
- Maximo 3 sessoes pendentes por agente
- Agentes apresentam via inbox card `WORKTREE_<agent>_<nome>_<YYYYMMDD>.md`
- CTO pode revisar com `vennon wt <sessao-do-agente>`
- Regras completas: `self/superego/worktrees.md`

---

## Integrar com vennon

Apos criar sessao, o runner sabe usar os worktrees:

```bash
vennon monolito start \
  --worktree=gandalf/auth-refactor
```

O `--worktree` resolve automaticamente para
`/workspace/home/worktree/gandalf-auth-refactor/monolito/`.
