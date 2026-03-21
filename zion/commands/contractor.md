---
name: contractor
description: Ponto de entrada unificado para contractors — briefing de status, reunião interativa com qualquer contractor, dashboard de worktrees, e delegação à Coruja para trabalho na plataforma estratégia.
---

# /contractor — Central dos Contractors

```
/contractor                    → briefing completo (GitHub, repos, tasks, worktrees)
/contractor call <nome>        → reunião interativa com um contractor
/contractor worktrees          → dashboard de worktrees
/contractor suggestions        → revisar propostas de worktrees pendentes
/contractor <pedido>           → delega à Coruja (plataforma estratégia)
```

Contractors disponíveis: `coruja` `mechanic` `tamagochi` `wanderer` `assistant`

---

## Roteamento

Parsear `$ARGUMENTS`:

| Argumento | Ação |
|-----------|------|
| vazio / `briefing` / `status` | **→ Briefing** |
| `call <nome>` | **→ Reunião** |
| `worktrees` / `worktree` | **→ Worktrees** |
| `suggestions [list\|next\|accept\|discard\|commit\|reset]` | **→ Suggestions** |
| qualquer outra coisa | **→ Coruja** |

---

## Briefing (padrão)

Panorama completo do workspace. Coletar tudo em paralelo:

### GitHub
```bash
WS=/workspace source /workspace/stow/.claude/scripts/gh-status.sh && gh_status_fetch && \
  echo "MY_PRS=$GH_MY_PRS_COUNT" && echo "REVIEW=$GH_REVIEW_COUNT" && \
  echo "---MY_PRS---" && echo "$GH_MY_PRS" && \
  echo "---REVIEW_PRS---" && echo "$GH_REVIEW_PRS"
```

### Repos locais
```bash
git -C /workspace/mnt status --short | head -10
git -C /workspace/mnt worktree list | head -20

for repo in /home/claude/projects/estrategia/*/; do
  name=$(basename "$repo")
  dirty=$(git -C "$repo" status --short 2>/dev/null | wc -l)
  branch=$(git -C "$repo" branch --show-current 2>/dev/null || echo "?")
  ahead=$(git -C "$repo" rev-list --count '@{upstream}..HEAD' 2>/dev/null || echo "?")
  [[ "$dirty" -gt 0 || "$ahead" != "0" ]] && echo "$name [$branch] dirty:$dirty ahead:$ahead"
done
```

### Tasks
```bash
echo "TODO:" && ls /workspace/obsidian/contractors/_schedule/ 2>/dev/null | wc -l
echo "DOING:" && ls /workspace/obsidian/tasks/DOING/ 2>/dev/null
echo "FAILED:" && ls /workspace/obsidian/tasks/failed/ 2>/dev/null || echo "(nenhum)"
echo "DONE_RECENT:" && ls -t /workspace/obsidian/contractors/*/done/ 2>/dev/null | head -5
```

### Output
```
╭─ Briefing DD/MM/YYYY ─────────────────────────────────────╮

 GitHub
  PRs meus abertos: N  |  Aguardando review: N

 Repos com mudanças
  repo [branch] dirty:N ahead:N

 Tasks
  DOING: nome-da-task
  TODO: N na fila | Failed: N

 Worktrees
  N ativos | N prunable

 Atenção
  ⚠ alertas relevantes

╰────────────────────────────────────────────────────────────╯
```

Máximo 5 recomendações acionáveis ao final. Nunca listar repos sem dirty/ahead.

**Filtros opcionais:** `gh` `repos` `tasks` `workers` → só aquela seção.

---

## Reunião — `call <nome>`

Convoca um contractor para conversa interativa. O contractor responde em primeira pessoa.

### 1. Carregar contexto
```bash
cat /workspace/obsidian/contractors/<nome>/memory.md 2>/dev/null
cat /workspace/obsidian/contractors/<nome>/DIARIO.md 2>/dev/null
```

### 2. Anunciar
```
╔══════════════════════════════════════════╗
║  Reunião com: <NOME>                     ║
║  Última execução: <data>                 ║
╚══════════════════════════════════════════╝
```

### 3. Incorporar o contractor

Você **é** o contractor. Voz por contractor:

| Contractor | Voz |
|------------|-----|
| coruja | Vigilante, factual, sem alarmes falsos |
| mechanic | Prático, direto, pensa em camadas |
| tamagochi | Inocente, curioso, confuso com prazer |
| wanderer | Sábio, contemplativo, observa antes de falar |
| assistant | Atencioso, levemente preocupado, direto |

Tópicos se o user não perguntar: descobertas recentes, preocupações, surpresas, recado pro CTO.

### 4. Encerrar

Quando user sinalizar fim: oferecer salvar resumo em `contractors/<nome>/DIARIO.md`.

---

## Worktrees

Dashboard de worktrees isolados:

```bash
git -C /workspace/mnt worktree list
```

Mostrar:
- **Status atual** — se está em worktree agora
- **Worktrees ativos** — branch, tempo ativo, mudanças
- **Prunable** — órfãos a limpar (`git worktree prune`)

```
🔀 WORKTREES

  Atual: <nome> [<branch>] — entrou há Xmin, Y arquivos modificados

  Ativos:
    nome1  [branch]  desde HH:MM
    nome2  [branch]  desde HH:MM

  Prunable (limpar com git worktree prune):
    nome3  [branch removida]
```

---

## Coruja — qualquer outro pedido

Se `$ARGUMENTS` não bater em nenhum padrão acima, delegar à Coruja:

```
Agent subagent_type=Coruja prompt="$ARGUMENTS"
```

A Coruja é especialista em monolito (Go), bo-container (Vue 2) e front-student (Nuxt 2). Interpreta o pedido e executa a skill adequada.

Exemplos de pedidos que vão pra Coruja:
```
/contractor FUK2-1234                → orquestra feature
/contractor review PR #123           → review de PR
/contractor go-test auth             → testa módulo
/contractor novo handler GET /users  → cria endpoint
/contractor progress                 → snapshot da feature
```
