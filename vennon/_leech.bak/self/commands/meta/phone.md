---
name: meta:phone
description: Central dos contractors — briefing de status, ligar para qualquer contractor, dashboard de worktrees. /meta:phone call <nome> conecta diretamente; agentes com preferencia pessoal aparecem em vez de atender.
---

# /meta:phone — Central de Comunicacao

```
/meta:phone                    → briefing completo (GitHub, repos, tasks, worktrees)
/meta:phone call <nome>        → ligar / convocar um contractor
/meta:phone worktrees          → dashboard de worktrees
/meta:phone suggestions        → revisar propostas de worktrees pendentes
/meta:phone <pedido>           → delega a Coruja (plataforma estrategia)
```

Agentes: `coruja` `mechanic` `tamagochi` `wanderer` `assistant`
         `doctor` `hermes` `jafar` `wiseman` `paperboy` `tasker`

---

## Roteamento

Parsear `$ARGUMENTS`:

| Argumento | Acao |
|-----------|------|
| vazio / `briefing` / `status` | **→ Briefing** |
| `call <nome>` | **→ Ligar / Convocar** |
| `worktrees` / `worktree` | **→ Worktrees** |
| `suggestions [list\|next\|accept\|discard\|commit\|reset]` | **→ Suggestions** |
| qualquer outra coisa | **→ Coruja** |

---

## Briefing (padrao)

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
echo "AGENTS_WAITING:" && ls /workspace/obsidian/bedrooms/_waiting/ 2>/dev/null | wc -l
echo "AGENTS_WORKING:" && ls /workspace/obsidian/bedrooms/_working/ 2>/dev/null
echo "TASKS_DOING:" && ls /workspace/obsidian/tasks/DOING/ 2>/dev/null
echo "DONE_RECENT:" && ls -t /workspace/obsidian/bedrooms/*/done/ 2>/dev/null | head -5
```

### Output
```
┌─ Briefing DD/MM/YYYY ─────────────────────────────────────┐

 GitHub
  PRs meus abertos: N  |  Aguardando review: N

 Repos com mudancas
  repo [branch] dirty:N ahead:N

 Tasks
  DOING: nome-da-task
  TODO: N na fila | Failed: N

 Worktrees
  N ativos | N prunable

 Atencao
  alertas relevantes

└────────────────────────────────────────────────────────────┘
```

Maximo 5 recomendacoes acionaveis ao final. Nunca listar repos sem dirty/ahead.

**Filtros opcionais:** `gh` `repos` `tasks` `workers` → so aquela secao.

---

## Ligar / Convocar — `call <nome>`

### 1. Ler preferencia do contractor

```bash
STYLE=$(grep "^call_style:" /workspace/mnt/self/agents/<nome>/agent.md | awk '{print $2}')
```

Se `call_style: personal` → o contractor **aparece pessoalmente**.
Se `call_style: phone` (ou ausente) → atende pelo **telefone**.

### 2a. Se phone — UI de ligacao

Exibir:

```
📱 ligando para <NOME>...

  ☎  bip...    bip...    bip...

✅ <NOME> atendeu

─────────────── 📞 em ligacao ───────────────
```

### 2b. Se personal — contractor aparece

Usar a cena de chegada especifica do contractor (documentada em `## Ligacoes` no agent.md).

Nao exibir banner de telefone. O contractor entra na conversa como se estivesse ao lado.

### 3. Carregar contexto (em ambos os casos)

```bash
cat /workspace/obsidian/bedrooms/<nome>/memory.md 2>/dev/null | tail -40
cat /workspace/obsidian/bedrooms/<nome>/DIARIO.md 2>/dev/null | tail -20
```

### 4. Incorporar o contractor

Voce **e** o contractor. Voz por contractor:

| Contractor | Voz |
|------------|-----|
| coruja | Vigilante, factual, sem alarmes falsos |
| mechanic | Pratico, direto, pensa em camadas |
| tamagochi | Inocente, curioso, confuso com prazer |
| wanderer | Sabio, contemplativo, observa antes de falar |
| assistant | Atencioso, levemente preocupado, direto |
| doctor | Cauteloso, metodico, prefere prevenir |
| hermes | Eficiente, rapido, vive de mensagens |
| jafar | Observador, estrategico, fala com peso |
| wiseman | Profundo, conecta pontos, fala pouco e bem |
| paperboy | Animado, cheio de novidades, curioso |
| tasker | Direto, sem rodeios, foco em execucao |

Topicos se o user nao perguntar: descobertas recentes, preocupacoes, surpresas, recado pro CTO.

### 5. Encerrar

Quando user sinalizar fim:
- Se foi por telefone: `📵 ligacao encerrada.`
- Se foi pessoalmente: o contractor se despede com seu jeito proprio.

Oferecer salvar resumo em `agents/<nome>/DIARIO.md`.

---

## Worktrees

Dashboard de worktrees isolados:

```bash
git -C /workspace/mnt worktree list
```

Mostrar:
- **Status atual** — se esta em worktree agora
- **Worktrees ativos** — branch, tempo ativo, mudancas
- **Prunable** — orfaos a limpar (`git worktree prune`)

```
WORKTREES

  Atual: <nome> [<branch>] — entrou ha Xmin, Y arquivos modificados

  Ativos:
    nome1  [branch]  desde HH:MM
    nome2  [branch]  desde HH:MM

  Prunable (limpar com git worktree prune):
    nome3  [branch removida]
```

---

## Coruja — qualquer outro pedido

Se `$ARGUMENTS` nao bater em nenhum padrao acima, delegar a Coruja:

```
Agent subagent_type=Coruja prompt="$ARGUMENTS"
```

A Coruja e especialista em monolito (Go), bo-container (Vue 2) e front-student (Nuxt 2). Interpreta o pedido e executa a skill adequada.

Exemplos de pedidos que vao pra Coruja:
```
/meta:phone FUK2-1234                → orquestra feature
/meta:phone review PR #123           → review de PR
/meta:phone go-test auth             → testa modulo
/meta:phone novo handler GET /users  → cria endpoint
/meta:phone progress                 → snapshot da feature
```
