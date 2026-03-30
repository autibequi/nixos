---
name: code:push
description: "Publica o trabalho — usa jj bookmark + jj git push se for repo jj, git push + gh pr se for git."
allowed-tools: Bash(jj *), Bash(gh pr *), Bash(git add:*), Bash(git push:*), Bash(git commit:*), Bash(git checkout --branch:*)
---

## Contexto

- É repo jj?: !`[ -d .jj ] && echo yes || echo no`
- Status: !`jj status 2>/dev/null || git status 2>/dev/null`
- Log: !`jj log --no-graph -r 'ancestors(@,5)' 2>/dev/null || git log --oneline -5 2>/dev/null`
- Bookmarks/branches: !`jj bookmark list 2>/dev/null || git branch -v 2>/dev/null`

## Sua tarefa

**Se for repo jj** (`.jj` existe):

1. Certifique que o commit tem descrição: `jj describe -m "mensagem"` se necessário
2. Crie ou mova o bookmark para o commit atual:
   ```bash
   jj bookmark create <nome-da-feature>     # se novo
   # OU
   jj bookmark set <nome-da-feature>        # se já existe
   ```
3. Push:
   ```bash
   jj git push --bookmark <nome-da-feature>
   ```
4. Abra PR via `gh pr create` se necessário

**Se for repo git** (sem `.jj`):

1. Crie branch se em main, commit, push e `gh pr create`

Baseie o nome do bookmark/branch no contexto do trabalho (ex: `feat/descricao`, `fix/bug`).
