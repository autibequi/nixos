---
name: leech/worktree
description: Sistema de sessoes multi-repo — leech wt. Cria, troca e gerencia sessoes de branches sincronizadas em todos os repos da Estrategia. Usar quando trabalhar em features que tocam multiplos repos ao mesmo tempo.
---

# Skill: leech/worktree

Gerencia sessoes de trabalho multi-repo via `leech wt`. Cada sessao representa
uma feature (ex: CARD-123) com branches checadas em paralelo em todos os repos
relevantes. Permite trocar de sessao instantaneamente com stash automatico.

---

## Interface

```bash
leech wt                     # lista sessoes (★ = ativa)
leech wt new CARD-123        # cria sessao (pede confirmacao)
leech wt CARD-123            # switch para sessao (stash auto)
leech wt main                # volta para main
leech wt CARD-123 --close    # deleta sessao
leech wt CARD-123 --force    # deleta sem confirmacao
```

---

## Estrutura no disco

```
/workspace/mnt/worktree/
├── .active                  ← sessao ativa atual ("main" ou "CARD-123")
└── CARD-123/
    ├── monolito/            ← branch CARD-123 do monolito
    ├── bo-container/        ← branch CARD-123 do bo-container
    ├── front-student/       ← branch CARD-123 do front-student
    └── toggler/             ← (e todos os outros repos em estrategia/)
```

Repos descobertos automaticamente: todos com `.git` em `/workspace/mnt/estrategia/`.

---

## Criar sessao (leech wt new)

```bash
leech wt new FUK2-12345
```

Mostra preview:
```
  monolito      branch nova  (base: HEAD)
  bo-container  branch existe (origin/FUK2-12345)
  front-student branch nova  (base: HEAD)

Confirmar? [s/N]
```

- Branch local existente → usa ela
- Branch remota existente → checkout com tracking
- Branch inexistente → cria nova a partir de HEAD

---

## Switch de sessao (leech wt)

```bash
leech wt FUK2-12345
```

Fluxo automatico:
1. Stash de arquivos pendentes na sessao atual (tag: `leech-wt-<sessao>`)
2. Atualiza `/workspace/mnt/worktree/.active`
3. Restaura stash da sessao alvo (se existir)

O stash e taggeado por sessao — nunca confunde entre sessoes diferentes.

---

## Sessao main

`leech wt main` nao tem diretorio fisico — aponta para os repos principais
em `/workspace/mnt/estrategia/`. Stash da sessao atual e salvo antes de sair.

---

## Integrar com leech runner

Apos `leech wt new CARD-123`, o runner ja sabe usar os worktrees:

```bash
leech runner monolito start \
  --worktree=FUK2-12345
```

O `--worktree` resolve automaticamente para
`/workspace/mnt/worktree/FUK2-12345/monolito/`.

---

## Fluxo tipico de feature multi-repo

```bash
# 1. Criar sessao
leech wt new FUK2-12345

# 2. Ativar
leech wt FUK2-12345

# 3. Trabalhar em cada repo (agente ou manualmente)
#    /workspace/mnt/worktree/FUK2-12345/monolito/
#    /workspace/mnt/worktree/FUK2-12345/bo-container/

# 4. Testar
leech runner monolito start --worktree=FUK2-12345
leech runner bo-container start --worktree=FUK2-12345

# 5. Commit/push em cada repo

# 6. Voltar pra main
leech wt main

# 7. Limpar quando merged
leech wt FUK2-12345 --close
```

---

## Agentes usando sessoes

Agente implementa feature em sessao propria e apresenta ao CTO:

```bash
# Agente cria sua sessao
leech wt new coruja/FUK2-12345

# Agente implementa nos worktrees

# Agente apresenta ao CTO (switch para a sessao do agente)
leech wt coruja/FUK2-12345
# → CTO pode testar direto nos worktrees

# CTO aprova, volta pra propria sessao
leech wt main
```

---

## Diferenca com worktrees de proposta (meta/rules/worktrees.md)

| | leech wt (este skill) | meta/rules/worktrees.md |
|---|---|---|
| **Para que** | Features do usuario nos repos da Estrategia | Agentes propondo mudancas ao Leech/sistema |
| **Path** | `/workspace/mnt/worktree/<sessao>/<repo>/` | `/tmp/<agente>-<data>-<nome>/` |
| **Repos** | Todos os repos em estrategia/ | Um repo por vez |
| **Switch** | `leech wt <sessao>` | Navegar no editor |
| **Stash** | Automatico no switch | Manual |
| **Apresentacao** | Pedro troca via leech wt | Inbox card WORKTREE_* |
