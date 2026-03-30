---
name: code:commit
description: "Salva o trabalho atual — usa jj describe se for repo jj, git commit se for repo git."
allowed-tools: Bash(jj *), Bash(git add:*), Bash(git status:*), Bash(git commit:*)
---

## Contexto

- É repo jj?: !`[ -d .jj ] && echo yes || echo no`
- Status atual: !`jj status 2>/dev/null || git status 2>/dev/null`
- Diff atual: !`jj diff 2>/dev/null || git diff HEAD 2>/dev/null`
- Log recente: !`jj log --no-graph -r 'ancestors(@,3)' 2>/dev/null || git log --oneline -5 2>/dev/null`

## Sua tarefa

**Se for repo jj** (`.jj` existe):
- NÃO use `git add` — não existe staging no jj
- Se o commit atual já tem mudanças, apenas atualize a descrição:
  ```bash
  jj describe -m "mensagem descritiva"
  ```
- Se quiser criar um novo ponto de salvamento:
  ```bash
  jj new -m "próxima etapa"
  ```

**Se for repo git** (sem `.jj`):
- Stage e commit normalmente com mensagem apropriada

Baseie a mensagem no que foi alterado. Seja conciso e descritivo.
