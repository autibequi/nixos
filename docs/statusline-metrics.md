# Métricas da status line (Claude Code)

O que cada campo significa, por que importa e que outras opções existem.

---

## Métricas atuais

### 1. `[████] 0/1M 0%` — **Contexto (context window)**

- **O que é:** Uso da janela de contexto do modelo: tokens já consumidos (input + cache) vs. tamanho máximo (ex.: 1M).
- **Por que importa:**
  - Quando o % sobe, o modelo “esquece” o que veio no início da conversa.
  - Afeta continuidade, referências a arquivos antigos e qualidade de respostas.
  - Em planos por uso, mais contexto ≈ mais custo.
- **Barra:** Preenchida conforme 0–100% do contexto usado.

---

### 2. `0s` / `1m` / `1h 5m` — **Duração (session duration)**

- **O que é:** Tempo total de uso da sessão atual (`cost.total_duration_ms`).
- **Por que importa:** Ver quanto tempo a sessão está ativa; útil para sessões longas e para correlacionar com custo.
- **Só aparece** quando > 0 (ex.: depois de alguma resposta).

---

### 3. `$0.00` — **Custo (cost USD)**

- **O que é:** Custo estimado em USD da sessão atual (vem do JSON do Claude Code).
- **Por que importa:** Controle de gasto com API; ver impacto de sessões longas ou com muitas respostas.
- **Só aparece** quando > 0.

---

### 4. `[████] Claudios:0` — **Claudios (workers em background)**

- **O que é:** Número de **containers de worker** em execução (every10, every60, every240).
- **Fonte:** `docker ps` com label `com.docker.compose.service=worker`.
- **Por que importa:** Quantos agentes/workers estão rodando em background; 0 = nenhum Bochecha ativo.
- **Barra:** Escala 0–5 (mais que 5 = barra cheia).

---

### 5. `[████] Bochechas:3` — **Bochechas (agentes em andamento)**

- **O que é:** Quantidade de **cards na coluna “Em Andamento”** do `vault/kanban.md` (THINKINGS) — agentes/tarefas rodando.
- **Por que importa:** Quantos agentes estão em execução ao mesmo tempo; evita sobrecarga e ajuda a priorizar.
- **Barra:** Escala 0–10.

---

### 6. `wt:nome` — **Worktree**

- **O que é:** Nome do worktree ativo (quando não estás na branch principal).
- **Por que importa:** Evitar confusão sobre em qual branch/worktree as mudanças estão.
- **Só aparece** quando há worktree.

---

### 7. `Opus 4.6 (1M context)` — **Modelo**

- **O que é:** Modelo em uso e tamanho da context window (ex.: 1M tokens).
- **Por que importa:** Saber capacidade (contexto, tipo de tarefa) e impacto em custo/latência.
- **Posição:** Extrema direita da status line.

---

## Outras opções (não mostradas hoje)

| Opção | Descrição | Prós | Contras |
|-------|-----------|------|--------|
| **Linhas editadas** (+x -y) | Já calculado no JSON (`total_lines_added/removed`); poderia ser exibido na linha. | Ver impacto da sessão no código. | Ocupa espaço; pode ser ruidoso. |
| **Custo da cota mensal** | Barra de uso a partir de `.ephemeral/usage-bar.txt`. Fontes: **Cursor /usage** (`CURSOR_API_KEY` → Current + Resets) ou **Anthropic** (`ANTHROPIC_ADMIN_KEY` → tokens 30d). | Ver uso vs. cota sem abrir bootstrap. | Requer uma das keys; status line recebe JSON, não arquivo. |
| **Inbox (kanban)** | Número de cards na coluna Inbox. | Ver carga de revisão. | Mais uma fonte (parsing do kanban). |
| **PRs / reviews** | Contagem de PRs meus e em review (como no JARVIS). | Visibilidade de trabalho pendente. | Requer `gh` + cache; mais pesado. |
| **Token input/output** | Contadores separados de tokens in/out da sessão. | Granularidade fina. | Depende do que o Claude Code envia no JSON. |
| **Erros / falhas** | Contagem de operações que falharam na sessão. | Debug rápido. | Schema do JSON pode não expor isso. |
| **Tempo desde último worker** | Idade do último log de worker (every10/60/240). | Saber se os timers estão vivos. | Exige leitura de arquivos de log; fora do JSON. |

---

## Onde está definido

- **Script:** `stow/.claude/scripts/statusline.sh` (e variante `statusline-compact.sh`).
- **Config:** `stow/.claude/settings.json` → `statusLine.command` aponta para o script.
- **Dados:** O Claude Code envia um JSON (stdin) com modelo, `context_window`, `cost`, `worktree`, etc.; o script formata e imprime uma única linha (stdout).

Para acrescentar uma métrica nova, é preciso: (1) ver se o JSON do Claude Code já traz o dado; (2) extrair com `jq` no script; (3) incluir na variável `RIGHT` (e, se quiser barra, usar a função `minibar`).
