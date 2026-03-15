# Propor — Pitch de mudança em worktree isolado

Cria um worktree, implementa uma mudança proposta, e apresenta o diff pro user decidir se aceita ou descarta.

## Entrada
- `$ARGUMENTS`: descrição da mudança proposta (texto livre)

## Instruções

1. Se `$ARGUMENTS` estiver vazio, perguntar o que quer propor.

2. **Criar worktree isolado:**
   - Usar `EnterWorktree` com name baseado no tema (ex: `propor-refactor-auth`, `propor-fix-banner`)
   - Worktree é criado em `.claude/worktrees/` com branch própria

3. **Implementar a mudança:**
   - Fazer as alterações propostas no worktree
   - Commitar com mensagem clara prefixada com `[proposta]`
   - Manter mudanças focadas — é um pitch, não um rewrite

4. **Apresentar o pitch:**
   ```
   ╭─ proposta: <titulo curto> ──────────────────╮

   ## O que muda
   <resumo em 2-3 bullets>

   ## Por que
   <motivação — qual problema resolve ou melhoria traz>

   ## Arquivos tocados
   <lista de arquivos modificados/criados/removidos>

   ## Diff
   <output do git diff resumido — mostrar as partes relevantes>

   ╰──────────────────────────────────────────────╯
   ```

5. **Perguntar ao user:**
   - Usar AskUserQuestion com opções:
     - **Aceitar** — merge da branch do worktree no branch original
     - **Aceitar parcial** — user indica quais arquivos/hunks quer
     - **Descartar** — remove worktree e branch, zero side effects

6. **Executar decisão:**
   - **Aceitar**: voltar pro workspace original (`ExitWorktree` com `keep`), fazer `git merge --no-ff <branch>` ou cherry-pick, depois limpar worktree
   - **Aceitar parcial**: perguntar quais partes, cherry-pick seletivo ou checkout de arquivos específicos
   - **Descartar**: `ExitWorktree` com `remove`

## Permissão de Worktrees
- Este comando é **sempre permitido** em sessões interativas (o user pediu explicitamente)
- Em **tasks autônomas** (workers), worktree só é permitido se o frontmatter tiver `worktrees: true`
- Sem `worktrees: true`, o worker NÃO pode usar EnterWorktree — deve apenas sugerir a mudança em texto (obsidian/sugestoes/)

## Regras
- SEMPRE criar worktree — nunca propor mudança direto no branch de trabalho
- Commits no worktree devem ser atômicos e bem descritos
- Mostrar diff REAL, não inventar — rodar `git diff` de verdade
- Se a proposta envolver muitos arquivos (>10), avisar o user antes de implementar
- Manter o pitch conciso — o user quer ver o que muda, não ler um essay
- Se o user rejeitar, limpar tudo sem deixar rastro
- Funciona em qualquer repo (workspace, projetos, etc)
