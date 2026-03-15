# Jarvis — Assistente pessoal de status

Panorama completo: GitHub, repos locais, THINKINGS, tasks autônomas, worktrees, e recomendações.

## Entrada
- `$ARGUMENTS`: filtro opcional (`gh`, `repos`, `tasks`, `workers`, `full`) — default: `full`

## Instruções

### 1. Coletar dados

#### 1a. GitHub (PRs remotos)
```bash
WS=/workspace source /workspace/stow/.claude/scripts/gh-status.sh && gh_status_fetch && \
  echo "MY_PRS=$GH_MY_PRS_COUNT" && echo "REVIEW=$GH_REVIEW_COUNT" && \
  echo "---MY_PRS---" && echo "$GH_MY_PRS" && \
  echo "---REVIEW_PRS---" && echo "$GH_REVIEW_PRS"
```

#### 1b. Repos locais (dirty/branches)
Varrer `/workspace` (NixOS host config) e `/home/claude/projects/estrategia/*/`:
```bash
# Workspace (este repo)
git -C /workspace status --short | head -10
git -C /workspace worktree list | head -20

# Projetos de trabalho — só os com dirty ou ahead
for repo in /home/claude/projects/estrategia/*/; do
  name=$(basename "$repo")
  dirty=$(git -C "$repo" status --short 2>/dev/null | wc -l)
  branch=$(git -C "$repo" branch --show-current 2>/dev/null || echo "?")
  ahead=$(git -C "$repo" rev-list --count '@{upstream}..HEAD' 2>/dev/null || echo "?")
  [[ "$dirty" -gt 0 || "$ahead" != "0" ]] && echo "$name [$branch] dirty:$dirty ahead:$ahead"
done
```

#### 1c. THINKINGS (kanban)
Ler `/workspace/obsidian/kanban.md`:
- Inbox, Em Andamento, Esperando Review, Backlog, Aprovado (hoje), Falhou

#### 1d. Tasks autônomas (Obsidian)
```bash
echo "pending:" && ls /workspace/obsidian/_agent/tasks/pending/ 2>/dev/null
echo "running:" && ls /workspace/obsidian/_agent/tasks/running/ 2>/dev/null
echo "failed:" && ls /workspace/obsidian/_agent/tasks/failed/ 2>/dev/null
echo "done_recent:" && ls -t /workspace/obsidian/_agent/tasks/done/ 2>/dev/null | head -5
```

#### 1e. Worktrees
```bash
git -C /workspace worktree list
# Prunable = lixo, pode limpar
# Active = trabalho em andamento
```

### 2. Montar briefing

Apresentar em formato limpo e acionável:

```
╭─ Briefing DD/MM/YYYY ─────────────────────────────────────╮

 GitHub
  PRs meus abertos: N
    repo  titulo-do-pr
  Aguardando meu review: N
    repo  titulo (autor)

 Repos Locais
  workspace [main] dirty:N  ← este repo NixOS
  repo-name [branch] dirty:N ahead:N
  repo-name [branch] dirty:N ahead:N

 THINKINGS
  Em Andamento: N
    [/] nome — descrição
  Esperando Review: N
    [!] nome — descrição
  Backlog: N items | Aprovado hoje: N

 Workers & Tasks
  Recorrentes: N (N running agora)
  Pending: task1, task2
  Failed: task1
  Done hoje: task1, task2

 Worktrees: N ativos, N prunable (lixo)
  ativos: nome1, nome2
  prunable: nome1, nome2 ← limpar com git worktree prune

 Atenção (alertas)
  ⚠ itens que precisam de ação

╰────────────────────────────────────────────────────────────╯
```

### 3. Recomendações

Dar **recomendações curtas e diretas** baseadas no que encontrou:

**GitHub:**
- Muitos PRs pra review → "N PRs esperando teu review, bom limpar"
- PRs meus abertos há tempo → "PRs XYZ abertos, verificar se já foram aprovados"
- PRs de release (estrategiaci) → "Release PRs pendentes, verificar se é hora de mergear"

**Repos locais:**
- Repos com dirty files → "N repos com mudanças não commitadas"
- Repos com commits ahead → "repo X tem N commits não pushados"
- Branches feature antigas → "repo X ainda no branch feature, mergear ou voltar pra main?"

**THINKINGS:**
- Inbox não vazio → "Inbox com N itens, worker processa em breve"
- Muito WIP → "N itens em andamento, foca em fechar antes de abrir"
- Esperando review → "N propostas minhas esperando tua review — /suggestions"
- Tasks falhando → "N tasks falharam, investigar"

**Workers:**
- Tasks pending acumulando → "N tasks pendentes, workers podem estar lentos"
- Tasks failed → "task X falhou, ver relatório"
- Worktrees prunable → "N worktrees órfãs, limpar com git worktree prune"
- Muitos worktrees ativos → "N worktrees ativos, considerar mergear/descartar"

### 4. Filtros ($ARGUMENTS)

| Filtro | Seções |
|--------|--------|
| `gh` | Só GitHub |
| `repos` | Só repos locais |
| `tasks` | THINKINGS + tasks autônomas |
| `workers` | Workers + worktrees |
| `full` ou vazio | Tudo + recomendações |

## Regras
- NUNCA editar arquivos — comando somente leitura
- Direto e acionável — sem enrolação
- Markdown formatting (não ANSI codes)
- Cache GitHub: 10min (via gh-status.sh)
- Se `gh` falhar, mostrar seção sem dados e avisar
- Repos sem dirty e sem ahead: NÃO listar (só mostrar os que têm algo)
- Worktrees: separar ativos de prunable
- Recomendações: máximo 5, as mais importantes
