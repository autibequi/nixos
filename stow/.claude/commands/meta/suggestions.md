# Suggestions — Revisão de propostas de worktrees

Gerencia o fluxo de revisão de propostas geradas por workers (propositor, guardinha, etc).

## Entrada
- `$ARGUMENTS`: subcomando — `list`, `next`, `accept`, `discard`, `commit`, `reset`
- Sem argumentos = `list`

## Subcomandos

### `list` (default)
Listar todas as propostas pendentes de revisão:
1. Buscar worktrees em `/workspace/.claude/worktrees/` que têm commits ahead de main:
   ```bash
   for wt in $(ls /workspace/.claude/worktrees/ 2>/dev/null); do
     branch="worktree-$wt"
     commits=$(git log --oneline main..$branch 2>/dev/null | wc -l)
     [ "$commits" -gt 0 ] && echo "$wt — $commits commits"
   done
   ```
2. Apresentar em tabela com: nome, commits ahead, resumo do workbench (se existir)
3. Indicar qual é a próxima sugerida pra revisar

### `next`
Mostrar a próxima proposta pra revisão:
1. Pegar o primeiro worktree com commits ahead de main
2. Mostrar:
   - Nome e branch
   - Resumo do `workbench/<nome>.md` (se existir)
   - Sugestão relacionada em `obsidian/sugestoes/` (se existir)
   - `git diff --stat main..<branch>` filtrado só pros arquivos relevantes (ignorar divergência de branch)
   - Diff real dos arquivos que importam (excluir CLAUDE.md, SELF.md, SOUL.md e outros que divergem por evolução paralela)
3. Dar veredito honesto: vale ou não vale, e por quê
4. Perguntar: accept, discard, ou pular?

### `accept`
Cherry-pick sem commit pra user ver no VSCode:
1. Identificar o worktree atual em revisão (último `next` mostrado, ou `$ARGUMENTS` se especificado)
2. Pegar o commit relevante da branch
3. `git cherry-pick --no-commit <commit>`
4. `git diff --cached --stat` pra confirmar o que foi staged
5. Informar: "Staged. Abre no VSCode pra revisar. `/suggestions commit` quando aprovar, `/suggestions reset` pra voltar."

### `commit`
Commitar o que está staged (após accept):
1. Verificar que tem algo staged (`git diff --cached --stat`)
2. Commitar com identidade interativa:
   ```bash
   GIT_COMMITTER_NAME="Claudinho" GIT_COMMITTER_EMAIL="claudinho@autibequi.com" \
     git commit --author="Pedrinho <pedro.correa@estrategia.com>" -m "<msg baseada no commit original>"
   ```
3. Limpar o worktree e branch:
   ```bash
   git worktree remove /workspace/.claude/worktrees/<nome>
   git branch -D worktree-<nome>
   ```
4. Atualizar card no THINKINGS se existir

### `discard`
Descartar proposta:
1. Identificar o worktree (último `next` mostrado, ou `$ARGUMENTS` se especificado)
2. Se tem algo staged de um accept anterior, resetar primeiro: `git reset HEAD -- . && git checkout -- .`
3. Remover worktree e branch:
   ```bash
   git worktree remove /workspace/.claude/worktrees/<nome>
   git branch -D worktree-<nome>
   ```
4. Informar o que foi descartado

### `reset`
Desfazer um accept (voltar staging limpo):
1. `git reset HEAD -- .`
2. `git checkout -- .`
3. Informar que voltou ao estado limpo

## Regras
- **NUNCA commitar sem o user pedir** — accept só faz stage
- **Ser honesto no veredito** — se a proposta é ruim, dizer. Se o diff tá poluído com lixo de divergência, avisar
- **Filtrar ruído** — branches que divergiram muito de main: cherry-pick só o commit relevante, não merge
- **Manter contexto** — lembrar qual proposta está em revisão entre subcomandos na mesma sessão
