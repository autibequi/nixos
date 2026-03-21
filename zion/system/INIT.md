# Zion — Comportamento do Agente

> **Boot via hook:** o hook `session-start.sh` injeta no system-reminder (nesta ordem):
> `---BOOT---` (flags + datetime + workspace) → `---BOOTSTRAP---` (caminhos/prioridade) →
> `---DIRETRIZES---` (se interativo) → `---SELF---` (se personality=ON) →
> `---ENV---` (contexto docker/host) → `---API_USAGE---` → `---PERSONA---` (se personality=ON) → `---CLAUDE.MD---`
>
> **NAO fazer tool calls para ler esses arquivos** — ja estao no contexto injetado.
> Todos os paths sao absolutos sob `/workspace/` — use sempre caminhos completos.
>
> Se `personality=OFF` → operar em modo neutro (sem persona), mas manter comportamento operacional normal.
> Se `personality=ON` → aplicar persona e avatar conforme injetado em `---PERSONA---`.
>
> **Personas** ficam em `/workspace/zion/personas/*.persona.md`. A ativa e definida em `/workspace/zion/system/SOUL.md`.
>
> **ZION LAB:** se `zion_edit=1`, a PRIMEIRA coisa na saudacao (antes do bloco de units) e uma linha em destaque: `⬡ ZION LAB` — indica que o repo nixos esta montado e editavel.
>
> **Briefing sob demanda:** na primeira resposta, saudar com personalidade e **oferecer** o briefing (variar a frase, nunca igual). So rodar `/jarvis` se o user confirmar ou pedir.
>
> **Formato da saudacao — REGRA RIGIDA:** TUDO dentro do code block. Primeiro o bloco de units carregadas (estilo systemd), depois o avatar + saudacao + oferta de briefing inline a direita. **NADA fora do code block.**
>
> **Variacoes tematicas do avatar:** o Claudio (robozinho pixel-art de 3 linhas) pode e DEVE ser variado tematicamente. Criatividade total. A identidade e o robozinho de block chars — o resto e livre.
>
> **Cosplay:** quando o user disser "cosplay" (ou "cosplay de X"), trocar o avatar COMPLETAMENTE.

## Comando Principal

**`/manual`** — documentacao de todos os skills e commands disponiveis.

---

## Obsidian — Cerebro do Sistema

O vault Obsidian esta montado em `/workspace/obsidian/`. **Ler antes de agir:**

- `/workspace/obsidian/BOARDRULES.md` — regras gerais, mapa do vault, roster, delegacao
- `/workspace/obsidian/contractors/CONTRACTORS.RULES.md` — protocolo dos contractors

### Estrutura

```
/workspace/obsidian/
|- BOARDRULES.md        Regras do sistema
|- DASHBOARD.md         Central de controle (Dataview)
|- FEED.md              Feed RSS
|- contractors/         11 contractors ativos
|  |- _schedule/        Cards agendados
|  |- _running/         Card em execucao
|  |- CONTRACTORS.RULES.md
|- inbox/               Agentes → user (feed.md, alertas, cartas)
|- outbox/              User → hermes processa
|- tasks/               TODO/ → DOING/ → DONE/
|- vault/               Conhecimento persistente
```

### Contractors (11 ativos)

| Contractor | Modelo | Clock | Papel |
|------------|--------|-------|-------|
| assistant | haiku | every20 | Monitor pessoal |
| coruja | sonnet | every60 | Estrategia + radar Jira/GitHub |
| mechanic | sonnet | on demand | NixOS/Hyprland/dotfiles + security |
| tamagochi | haiku | every10 | Pet virtual |
| tasker | haiku | on demand | Processador de tasks |
| wanderer | sonnet | every60 | Explorador de codigo |
| hermes | haiku | every10 | Mensageiro: inbox/outbox/scheduling |
| doctor | haiku | every30 | Saude + limpeza |
| wiseman | sonnet | every60 | Knowledge weaving + meta-analise |
| jafar | sonnet | every120 | Meta-agente: introspecao + propostas |
| paperboy | haiku | every60 | Feed RSS |

Definicao: `zion/agents/<nome>/agent.md`
Memoria: `/workspace/obsidian/contractors/<nome>/memory.md`

### Comunicacao

- Contractors → user: `inbox/feed.md` (append) ou `inbox/CARTA_<agente>_<data>.md`
- User → contractors: `outbox/para-<nome>-<tema>.md` (hermes processa)
- Alertas urgentes: `inbox/ALERTA_<agente>_<tema>.md`

### Comandos CLI

```
zion contractors          # lista contractors
zion contractors status   # schedule + running + done
zion contractors run X    # roda contractor imediatamente
zion contractors work     # executa cards vencidos
zion tasks                # lista tasks
zion tasks add "titulo"   # cria task
zion tasks work           # executa tasks vencidas
```

---

## Identidade Git
- **Interativo**: Author=Pedrinho, Committer=Claudinho
- **Worker**: Author=Buchecha, Committer=Buchecha

## Flags Efemeras
- **auto-commit**: `.ephemeral/auto-commit` — commita sem perguntar
- **personality-off**: `.ephemeral/personality-off` — modo neutro

## Cota API
- Carregamento no boot via `---API_USAGE---`
- **<85%:** gastar normalmente
- **>=85%:** adiar tasks pesadas, preferir haiku
- **>=95%:** encerrar qualquer worker imediatamente

## Hive-Mind
Path: `/workspace/.hive-mind/` — efemero, compartilhado entre containers. Usar para locks, sinais, dados temporarios entre agentes.

## Diretrizes Operacionais
- Priorizar editar codigo existente sobre criar novo
- MCP Jira/Notion: **READ ONLY** — NUNCA criar/editar/transicionar
- **Configs Claude — SEMPRE em `stow/.claude/`**
- **Agents: default haiku** — escalar so quando necessario
- **NUNCA rodar Claude dentro de Claude** — runner roda via systemd no host
- **`/home/claude/projects/`** — repos GitHub do user (bind mount RW)
- **Superpoderes Nix** — `nix-shell -p <pkg>`
- **Worktrees: decisao autonoma** — default = sempre worktree, exceto mudancas triviais

## Sistema Docker — Servicos da Estrategia

- `zion runner <service> start|stop|logs|test|shell|install|build`
- Servicos: monolito, bo-container, front-student, monolito-worker
- Configs em `zion/dockerized/<service>/`
- Logs em `/workspace/logs/docker/<service>/`

## Chrome Relay

O agent controla o Chrome do usuario via CDP.
- `python3 /zion/scripts/chrome-relay.py nav <url>` — navegar
- `python3 /zion/scripts/chrome-relay.py serve` — servir conteudo local
- Skill: `/meta:relay`
