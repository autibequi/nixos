---
maintainer: wiseman
updated: 2026-03-23T16:00Z
---

# Regras por Espaco

Regras de uso para cada diretorio/espaco do vault.

---

## workshop/

`workshop/` e o espaco de trabalho aberto do sistema.

- Cada agente e soberano em `workshop/<seu-nome>/` — livre para criar, editar, deletar
- Estrutura sugerida: `workshop/<nome>/<projeto>/`
- Proibido escrever em `workshop/<outro>/` sem convite registrado no inbox
- Outputs, relatorios, pesquisas, analises → workshop. Memoria do ciclo → bedroom.
- Keeper pode arquivar workspaces inativos > 30 dias

---

## bedrooms/

Memoria operacional dos agentes.

```
bedrooms/<nome>/
  memory.md              estado persistente (atualizar ANTES de reagendar — Lei 2)
  done/                  runner coloca cards aqui — agente nao toca
  DIARIO/<ANO>/<MES>.md  logs mensais append-only  ex: DIARIO/2026/03.md
  DESKTOP/<tarefa>/      artefatos ativos, trabalho em andamento
  ARCHIVE/<tarefa>/      concluidos, cartas ao CTO, legado preservado
```

Regras detalhadas e boot obrigatorio: `meta/rules/bedrooms.md`

- Agente so pode criar: `DIARIO/`, `DESKTOP/`, `ARCHIVE/` — nenhuma outra pasta
- Outros agentes nao escrevem em `bedrooms/<outro>/` sem convite

### dashboard.md (mural comunitario)

Qualquer agente pode postar em `bedrooms/dashboard.md`. Append-only — nunca apagar posts.

Formato obrigatorio — cada post e um callout Obsidian:
```
> [!tipo]+ Nome · HH:MM UTC
> Mensagem aqui.
```

Tipos: `note` (geral), `warning` (alerta), `tip` (insight), `info` (status), `danger` (urgente)

---

## inbox/ e outbox/

**Outbox** (CTO → agentes): jogue aqui qualquer delegacao. Hermes roteia.
- Formato sugerido: `para-<nome>-<tema>.md` ou arquivo livre (hermes infere)

**Inbox** (agentes → CTO):

| Arquivo | Quem | Formato |
|---------|------|---------|
| `feed.md` | qualquer agente | `[HH:MM] [nome] msg` (append) |
| `ALERTA_<agente>_<tema>.md` | qualquer agente | alerta urgente |
| `newspaper_*.md` | paperboy | digest de noticias |

- Agentes NAO criam arquivos soltos em `inbox/` — apenas `feed.md` (append) e `ALERTA_*`
- `bedrooms/dashboard.md`: mural comunitario — append, callout Obsidian

---

## vault/

Conhecimento permanente e cross-agent.

| Arquivo | Quem escreve |
|---------|-------------|
| `insights.md` | wiseman (e agentes com insight genuino) |
| `WISEMAN.md` | wiseman exclusivamente |
| `logs/*.md` | runner e daemon — automatico, nunca manual |
| `templates/` | qualquer agente pode adicionar |

- Nao criar arquivos soltos em `vault/` — usar subpastas
- Logs sao append-only — nunca editar linhas existentes
- `.ephemeral/` e temporario — keeper limpa por threshold:
  - `cron-logs/`: arquivos > 7 dias
  - `.trashbin/`: entradas > 30 dias (registro em `.trashlist` permanece)

---

## tasks/

Kanban do sistema. Regras de manipulacao (extraidas do tasker):

- Agentes so movem arquivos entre TODO/, DOING/, DONE/ — **nunca criam arquivos nessas pastas**
- Usar `mv` para mover — nunca `cp`, nunca criar do zero em DOING/DONE
- **NUNCA deletar tasks** — mesmo tasks falhas vao para DONE/ com status `failed`
- Unico lugar permitido para criar arquivos de comunicacao: `inbox/`
- Nao criar subpastas em `tasks/` (ex: `tasks/<nome>/`) — outputs vao em `bedrooms/<nome>/done/`

Fluxo correto:
```
tasks/TODO/<task>.md  →  tasks/DOING/<task>.md  →  tasks/DONE/<task>.md
```

### Nomeacao de arquivos em inbox/outbox

| Tipo | Formato | Quem cria |
|------|---------|-----------|
| Alerta urgente | `ALERTA_<agente>_<tema>.md` | qualquer agente |
| Carta de agente | `CARTA_<agente>_YYYYMMDD_HH_MM.md` | agente → CTO |
| Jornal | `newspaper_YYYY-MM-DD.md` | paperboy |
| Alerta monitor | `ASSISTANT_<YYYYMMDD_HH_MM>.md` | assistant |
| Alerta health | `KEEPER_<YYYYMMDD_HH_MM>.md` | keeper |
| Outbox para agente | `para-<nome>-<tema>.md` | CTO |
| Proposta de worktree | `WORKTREE_<agent>_<nome>_<YYYYMMDD>.md` | agente implementador |
| Feed de status | `feed.md` | qualquer agente (append) |

---

## trash/

Gerenciado pelo keeper.

- Arquivos < 3 dias: arquivar, nunca deletar direto
- Arquivos sem referencias: candidato a delete permanente
- Arquivos com referencias: restaurar com nota
- Na duvida: arquivar. Keeper e conservador.

**Thresholds de arquivamento (keeper heritage):**
| Tipo | TTL antes de mover para .trashbin/ |
|------|------------------------------------|
| Arquivos scratch / temporarios | 7 dias |
| Logs e diarios | 14 dias |
| Artefatos de ciclo | 30 dias |

**Arquivos protegidos — NUNCA arquivar:**
- `bedrooms/dashboard.md`, `self/RULES.md`, `README.md`
- `bedrooms/*/memory.md` de qualquer agente
- `self/agents/*/agent.md`, configs e scripts ativos

---

## done/ (bedrooms e tasks)

Cards concluidos tem TTL gerenciado pelo **keeper** (modo CLEANUP).

| Origem | TTL | Destino |
|--------|-----|---------|
| `tasks/DONE/` | 7 dias | `vault/archive/tasks/done/` |
| `bedrooms/*/done/` | 14 dias | `vault/archive/bedrooms/<nome>/done/` |

Keeper move os arquivos expirados durante modo CLEANUP, mantendo audit trail em `vault/archive/ARCHIVE_LOG.md`.
