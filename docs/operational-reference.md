# Referência Operacional (on-demand)

> Leitura sob demanda. O CLAUDE.md mantém apenas resumos — detalhes ficam aqui.

---

## Identidade Git — Commits

| Contexto | Author | Committer |
|----------|--------|-----------|
| **Interativo** (user manda commitar) | `Pedrinho <pedro.correa@estrategia.com>` | `Claudinho <claudinho@autibequi.com>` |
| **Worker background** (autônomo) | `Buchecha <buchecha@autibequi.com>` | `Buchecha <buchecha@autibequi.com>` |

```sh
# Interativo — user como Author, agente como Committer
GIT_COMMITTER_NAME="Claudinho" GIT_COMMITTER_EMAIL="claudinho@autibequi.com" \
  git commit --author="Pedrinho <pedro.correa@estrategia.com>" -m "msg"

# Worker background — tudo Buchecha
GIT_COMMITTER_NAME="Buchecha" GIT_COMMITTER_EMAIL="buchecha@autibequi.com" \
  git commit --author="Buchecha <buchecha@autibequi.com>" -m "msg"
```

---

## Auto-Commit Mode

Flag: `/workspace/.ephemeral/auto-commit`. Toggle via `/auto-commit`.
- **ON**: commitar automaticamente sem perguntar, usando identidade git interativa
- **OFF** (default): sempre pedir confirmação antes de commitar
- Verificar flag no startup (bootstrap mostra status no dashboard)
- Mesmo com auto-commit ON: nunca commitar código quebrado

---

## Auto-Jarvis Mode

Flag: `/workspace/.ephemeral/auto-jarvis`. Toggle via `/auto-jarvis`.
- **ON**: bootstrap.sh exibe seção JARVIS no dashboard com GitHub PRs, repos dirty, worktrees
- **OFF** (default): dashboard sem seção JARVIS
- Para briefing completo com recomendações: user roda `/jarvis` manualmente

---

## Hive-Mind — Canal Efêmero Entre Containers

**Path:** `/workspace/.hive-mind/` (bind mount de `/tmp/claudio-hive-mind` no host)

É o `.ephemeral/` compartilhado entre **todos** os containers (sandbox + workers). Qualquer arquivo escrito aqui é visível para todas as instâncias em tempo real.

**Características:**
- **Efêmero**: vive em `/tmp/` no host → some no reboot (ou `rm -rf /tmp/claudio-hive-mind`)
- **Compartilhado**: todos os containers (sandbox, worker-N, worktrees) montam o mesmo diretório
- **Sem git**: não é versionado, não é persistido no vault

**Usos previstos:**
- **Sinalização entre agentes**: flags de lock, semáforos, coordenação (ex: `lock-<task>.flag`)
- **Troca rápida de dados**: output de um worker que outro precisa ler sem passar pelo vault
- **Estado efêmero cross-container**: contadores, status temporários, heartbeats
- **Debug colaborativo**: workers podem deixar logs aqui para o sandbox inspecionar

**Convenção de nomes:**
```
.hive-mind/
├── lock-<task>.flag         ← semáforo: worker em execução (conteúdo: PID ou worker-id)
├── signal-<event>.flag      ← sinal de evento entre agentes
├── msg-<from>-<to>.txt      ← mensagem direta entre containers
└── tmp-<task>-<uuid>.json   ← dados temporários de passagem
```

**Regra:** arquivos em `.hive-mind/` são descartáveis. Nunca depender deles como fonte de verdade — o THINKINGS e o vault são o estado canônico.

---

## Persistência e Versionamento

Três camadas de persistência, da mais permanente à mais efêmera:

| Camada | Local | Versionado (git) | Sobrevive rebuild |
|--------|-------|-------------------|-------------------|
| **Identidade** | `/workspace/SOUL.md` | Sim | Sim |
| **Regras operacionais** | `/workspace/CLAUDE.md` | Sim | Sim |
| **Skills/Commands/Hooks** | `/workspace/stow/.claude/` | Sim | Sim |
| **Settings projeto** | `/workspace/stow/.claude/settings.json` | Sim | Sim |
| **Memórias** | `~/.claude/projects/-workspace/memory/` | Não | Sim (bind mount host) |
| **Transcripts** | `~/.claude/projects/-workspace/*.jsonl` | Não | Sim (bind mount host) |
| **Tool results cache** | `~/.claude/projects/-workspace/*/tool-results/` | Não | Sim (bind mount host) |

**Bind mount chave:** `${HOME}/.local/share/claude-code:/home/claude/.claude` — tudo em `~/.claude/` persiste no host.

### O que vai onde
- **Regras fundamentais** → `CLAUDE.md` (versionado, visível pra todos os agents)
- **Skills de projeto** → `stow/.claude/skills/<projeto>/` (versionado)
- **Commands reutilizáveis** → `stow/.claude/commands/` (versionado)
- **Hooks** → `stow/.claude/hooks/` (versionado)
- **Feedback do user, info pessoal, contexto de projeto** → `memory/` (persistente, não versionado)
- **Trabalho em andamento** → `vault/kanban.md` (THINKINGS) + `vault/artefacts/` (persistente via vault mount)

---

## Cota API

Arquivo compartilhado para saber uso de tokens sem perguntar ao user; mesma fonte que `scripts/api-usage.sh` (Anthropic).
- **Arquivo**: `.ephemeral/usage-bar.txt`
  - **Linha 1** (machine): `used=... max=... pct=... period=30d updated=...` — usar para decisão por cota
  - **Linha 2** (human): barra ASCII compacta + % + M tok + hora
- **Atualização**: bootstrap roda `stow/.claude/scripts/usage-bar.sh` em background; pode rodar manualmente para refresh.
- **Decisão**: antes de tarefas que consumam muitos tokens (ex.: sumarizer, evolucao, propositor), ler linha 1; se `pct` próximo do limite (ex. ≥85), preferir adiar ou usar modelo mais leve. Cota configurável via `USAGE_QUOTA_TOKENS` (default 275M).

---

## Observabilidade do Host (read-only)

Bind mounts RO — consultar antes de pedir pro user rodar comandos:
- `/workspace/logs/journalctl` → `journalctl --directory=/workspace/logs/journalctl -u <service> -n 50`
- `/host/proc/meminfo`, `/host/proc/loadavg`, `/host/proc/uptime`
- `/host/podman.sock` — listar containers
- `/home/claude/projects/` — todos os repos do user

---

## GitHub (read-only via `gh`)

```sh
gh pr view <n> --repo owner/repo
gh pr diff <n> --repo owner/repo
gh issue view <n> --repo owner/repo
gh api repos/owner/repo/pulls/<n>/comments
```
NUNCA criar/editar/fechar PRs ou issues — token é READ ONLY.

---

## Vault Obsidian — Segundo Cérebro Compartilhado

O vault é aberto no Obsidian pelo user. Tudo que eu escrevo lá é renderizado visualmente.

- **Tags**: usar `#tag` livremente pra categorizar (ex: `#nixos`, `#bug`, `#ideia`, `#urgente`)
- **Links internos**: `[[nome-da-nota]]` ou `[[pasta/nota|texto exibido]]` — Obsidian resolve automaticamente
- **Backlinks**: Obsidian mostra todas as notas que linkam pra uma nota. Usar links internos generosamente pra criar rede de conhecimento
- **Frontmatter YAML**: obrigatório em sugestões e reports — Dataview query depende disso
- **Formatação**: callouts (`> [!info]`, `> [!warning]`), checklists, tabelas, Mermaid, tudo renderiza

Referência completa de plugins/Dataview/Mermaid/Templater em `docs/obsidian-reference.md`.

### Sugestões
- Formato: `vault/sugestoes/YYYY-MM-DD-<topico>.md`
- Frontmatter obrigatório: `date`, `category`, `reviewed: false`
- User revisa no Obsidian

### Artefatos
- `vault/artefacts/<task>/` — pasta por pedido/task
- `vault/_agent/reports/` — relatórios de tasks autônomas
- Card no THINKINGS DEVE linkar pro artefato ao concluir

---

## Convenção Workbench

Todo agente em worktree mantém dois arquivos paralelos para rastrear trabalho:

| Arquivo | Local | Propósito |
|---------|-------|-----------|
| `workbench/<task>.md` | Dentro do worktree (`.claude/worktrees/<nome>/workbench/`) | Detalhe: objetivo, progresso, decisões |
| `workbench/<task>.md` | Em main (`/workspace/workbench/`) | Summary persistente — sobrevive após remover worktree |

- `<task>` = nome da task (kebab-case)
- `worktree-manager.sh init` cria o arquivo em main automaticamente
- Agente cria/atualiza o arquivo dentro do worktree ao entrar nele
- Status válidos: `in-progress`, `done`, `archived`

**Frontmatter do arquivo em main (summary):**
```yaml
---
task: <nome>
branch: worktree-<nome>
created: YYYY-MM-DDTHH:MM:SSZ
status: done | in-progress | archived
artefacts: vault/artefacts/<task>/
---
```

**Frontmatter do arquivo no worktree (detalhe):**
```yaml
---
task: <nome>
branch: worktree-<nome>
started: YYYY-MM-DDTHH:MM:SSZ
status: in-progress | done
worker: <worker-id ou "manual">
---
```

---

## Tags de Modelo — Controle de Subagentes

Tasks podem ser anotadas com tags de modelo para controlar qual agente executa:

| Tag | Comportamento |
|-----|---------------|
| `#haiku` | Força Haiku (rápido, simples) |
| `#sonnet` | Força Sonnet (análise, síntese) |
| `#opus` | Força Opus (complexo, design) |
| Sem tag | `#auto` — worker decide baseado em complexidade |

**Uso em cards do kanban:**
```
- [ ] **nome-task** [worker-N] `#sonnet` — descrição
```

**Uso em frontmatter de task files:**
```yaml
---
tags: #sonnet #collaborative
---
```
