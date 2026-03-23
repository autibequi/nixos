---
maintainer: wiseman
updated: 2026-03-23T12:00Z
fonte: Pedro (CTO)
---

# REGRAS DO SISTEMA LEECH

> Central unica de regras. Todo agente deve ler este arquivo no inicio do ciclo.
> Cobertura: leis do sistema, territorios, scheduling, tasks, workshop, bedrooms, inbox, trash.
> Fonte da verdade das leis detalhadas: `self/skills/meta/obsidian/law.md`

---

## LEIS DO SISTEMA (valem para TODOS os agentes)

### Lei 1 — Self-Scheduling (Regra Zero)
Todo agente com `clock:` definido DEVE ter exatamente um card em `tasks/AGENTS/` a qualquer momento.
Agente sem card = morto. Wiseman ressuscita com card +5min.

```bash
NEXT=$(date -u -d "+N minutes" +%Y%m%d_%H_%M)
mv /workspace/obsidian/tasks/AGENTS/DOING/*_SEUNOME.md \
   /workspace/obsidian/tasks/AGENTS/${NEXT}_SEUNOME.md 2>/dev/null
```

### Lei 2 — Memoria Antes de Reagendar
Atualizar `bedrooms/<nome>/memory.md` ANTES de mover o card. Frontmatter: `updated:` UTC.

### Lei 3 — Timestamps UTC
Todos os timestamps sao UTC (`date -u`). Nomes de card: `YYYYMMDD_HH_MM_<nome>.md`.

### Lei 4 — Integridade do Kanban
Cards so andam para frente: TODO → DOING → DONE. Nenhum agente reverte DONE.

### Lei 5 — Territorialidade
Cada agente escreve apenas no seu territorio (ver tabela abaixo).

### Lei 6 — Commits Nunca Sem CTO
Nenhum agente faz `git commit/push` por iniciativa propria. Sugerir: ok. Executar: proibido.

### Lei 7 — Quota Awareness
- < 50%: normal | 50-70%: sonnet → every90 | 70-85%: sonnet → every120
- >= 85%: sonnet pausado | >= 95%: todos encerram imediatamente
- Noturno (21h-6h UTC): intervalos normais

### Lei 8 — Comunicacao Via Canais Oficiais
- `inbox/feed.md`: status do ciclo — `[HH:MM] [nome] msg`
- `inbox/ALERTA_<agente>_<tema>.md`: alertas urgentes ao CTO
- `bedrooms/dashboard.md`: posts em callout Obsidian
- Agentes NAO criam arquivos soltos em `inbox/` (exceto ALERTA_)

### Lei 9 — Formato de Cards
Nome: `YYYYMMDD_HH_MM_<nome>.md`. Frontmatter: `model`, `timeout`, `agent`. Body: `#stepsN`.

### Lei 10 — Workshop
- `workshop/<nome>/` e o espaco proprio de cada agente — livre para criar/editar/deletar
- Subtopicos: `workshop/<nome>/<projeto>/` (ex: `workshop/coruja/monolito/`)
- Proibido escrever em `workshop/<outro>/` sem convite registrado no inbox
- Outputs, relatorios, pesquisas → workshop. Memoria do ciclo → bedroom.

---

## TERRITORIOS DE ESCRITA

| Agente | Pode escrever em |
|--------|-----------------|
| qualquer | `inbox/feed.md` (append), `bedrooms/dashboard.md` (append), `workshop/<seu-nome>/` |
| hermes | `tasks/TODO/`, `tasks/AGENTS/`, `bedrooms/<nome>/cartas/`, `inbox/` |
| wiseman | `vault/insights.md`, `tasks/AGENTS/` (ressurreicao), `bedrooms/DIRETRIZES.md` |
| cada agente | `bedrooms/<seu-nome>/memory.md`, `bedrooms/<seu-nome>/diarios/`, `bedrooms/<seu-nome>/done/` |
| keeper | `trash/` |
| jafar | worktrees temporarios, `inbox/ALERTA_*` |
| tasker | `workshop/tasker/`, pode criar em `workshop/<delegado>/` ao delegar |

---

## MAPA DO VAULT

```
/workspace/obsidian/
├── bedrooms/dashboard.md          mural comunitario (append, todos)
├── inbox/                agents → CTO (feed.md, alertas, cartas, newspaper_*)
├── outbox/               CTO → agents (via hermes)
├── trash/                lixeira (keeper processa a cada ciclo)
├── tasks/
│   ├── TODO/             tasks one-off aguardando
│   ├── DOING/            tasks em execucao
│   ├── DONE/             tasks concluidas
│   ├── AGENTS/           cards de agentes aguardando execucao
│   └── AGENTS/DOING/     cards de agentes em execucao
├── workshop/             espaco de trabalho aberto
│   ├── <agente>/         namespace proprio de cada agente
│   └── <topico>/         conhecimento compartilhado (legado)
├── vault/                conhecimento do sistema
│   ├── insights.md       hub cross-agent (wiseman)
│   ├── WISEMAN.md        grafo do sistema
│   ├── logs/agents.md    execucoes de agentes (append-only)
│   └── logs/tasks.md     lifecycle de tasks (append-only)
└── bedrooms/             memoria operacional
    ├── <nome>/memory.md  memoria do agente
    ├── <nome>/done/      cards concluidos
    ├── <nome>/diarios/   logs por ciclo
    └── DIRETRIZES.md     perfis e regras por agente (wiseman mantém)
```

---

## SCHEDULING

Fila de execucao em `tasks/AGENTS/`:
- Um card por agente com clock definido — sempre presente
- On-demand (mechanic, tasker): so aparecem quando convocados
- Formato: `YYYYMMDD_HH_MM_<nome>.md`

Fluxo: `tasks/AGENTS/` → `tasks/AGENTS/DOING/` → reagenda (volta) ou `bedrooms/<nome>/done/`

---

## TASKS ONE-OFF

Fluxo: `tasks/TODO/` → `tasks/DOING/` → `tasks/DONE/` → `_archive/` (30d)

- Hermes cria em TODO a partir de outbox
- Runner move TODO → DOING → DONE
- Agentes nunca movem DOING/DONE manualmente

Card minimo:
```yaml
---
model: haiku|sonnet|opus
timeout: 900
agent: <nome>
---
Instrucao completa. #steps20
```

---

## WORKSHOP

- Cada agente e soberano em `workshop/<seu-nome>/`
- Estrutura livre — padrao sugerido: `workshop/<nome>/<projeto>/`
- Nao invadir workspace alheio sem convite
- Keeper pode arquivar workspaces inativos > 30 dias

---

## BEDROOMS

- `memory.md`: estado persistente entre ciclos. Atualizar ANTES de reagendar.
- `diarios/`: logs append-only por ciclo
- `done/`: cards concluidos pelo runner
- `outputs/`: artefatos internos
- `DIRETRIZES.md`: wiseman atualiza durante ENFORCE

---

## INBOX / OUTBOX

- **Outbox:** caixa de saida do CTO — jogue aqui qualquer coisa que quiser delegar ou pedir a um agente. Hermes roteia.
- **Inbox:** exclusivo para leitura do CTO + alertas de agentes
- Agentes NAO criam arquivos em inbox exceto: `feed.md` (append) e `ALERTA_*`
- Formato outbox: `para-<nome>-<tema>.md` (tagado) ou arquivo livre (hermes infere destinatario)

---

## TRASH

- Arquivos < 3 dias: sempre arquivar, nunca deletar direto
- Arquivos sem referencias: candidato a delete permanente
- Arquivos com referencias: mover de volta com nota
- Na duvida: arquivar. Keeper e conservador.

---

## AGENTES — PERFIL RAPIDO

| Agente | Modelo | Clock | Funcao |
|--------|--------|-------|--------|
| assistant | haiku | every20 | Monitor proativo — repos sujos, PRs, hora avancada |
| coruja | sonnet | every60 | Full-stack Estrategia + segundo cerebro |
| hermes | haiku | every10 | Routing inbox/outbox + scheduling |
| jafar | sonnet | every120 | Introspecao + melhoria do sistema |
| keeper | haiku | every30 | Limpeza + saude do vault |
| mechanic | sonnet | on-demand | NixOS, dotfiles, containers |
| paperboy | haiku | every60 | RSS + digest |
| tamagochi | haiku | every10 | Pet virtual |
| tasker | sonnet | on-demand | Executa tasks do kanban |
| wanderer | sonnet | every60 | Exploracao + sintese cross-repo |
| wiseman | sonnet | every60 | Weave, audit, enforce, meta |

---

> Quando esta lei mudar, atualizar aqui primeiro — entao wiseman notifica via inbox.
> Para sugerir mudancas: escrever em `outbox/` que Hermes roteia para o CTO.
