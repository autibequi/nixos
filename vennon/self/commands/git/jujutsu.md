---
name: git:jujutsu
description: "Carrega o contexto completo do Jujutsu (jj) — workflow, comandos, bookmarks, colaboração git. Usar em qualquer sessão num repo jj."
allowed-tools: Bash(jj *), Bash(gh pr *), Bash(gh pr create:*), Bash(gh pr list:*), Bash(gh pr view:*)
---

## Contexto — Estado do repo

- Status atual: !`jj status 2>/dev/null || echo "jj não disponível"`
- Log recente: !`jj log --no-graph -r 'ancestors(@, 5)' 2>/dev/null || echo "jj não disponível"`
- Bookmarks: !`jj bookmark list 2>/dev/null || echo "sem bookmarks"`

## Skill carregada

Leia e aplique **todo o conteúdo** de `/workspace/self/skills/git/jujutsu/SKILL.md`.

Isso inclui:
- Regras de o que NÃO fazer (sem git add, sem git worktree, sem git branch)
- Comandos jj para criar/modificar/navegar commits
- Workflow completo com bookmarks para GitHub/GitLab
- Revsets e resolução de conflitos

## Sua tarefa

A partir daqui, todas as operações de VCS devem usar `jj`. Não use `git` diretamente a não ser para operações sem equivalente em `jj` (ex: `gh pr create`).

Se o usuário pedir algo como "commitar", "salvar", "criar branch", "fazer push", traduzir automaticamente para os equivalentes jj.
