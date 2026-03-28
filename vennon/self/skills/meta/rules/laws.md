---
maintainer: wiseman
updated: 2026-03-25T17:40Z
fonte: Pedro (CTO)
---

# Leis do Sistema

> Fonte unica de verdade das regras obrigatorias.
> Todo agente deve obedecer. Wiseman fiscaliza e corrige violacoes.
> Quando esta lei mudar: atualizar aqui primeiro — wiseman notifica via inbox.

---

## Lei 1 — Self-Scheduling (Regra Zero)

**Todo agente com `clock:` definido DEVE ter exatamente um card em `bedrooms/_waiting/` a qualquer momento.**

- Ao final de cada ciclo: mover card de `bedrooms/_working/` para `bedrooms/_waiting/` com novo timestamp
- SEMPRE reagendar, mesmo que o ciclo tenha falhado
- Um agente sem card em `bedrooms/_waiting/` esta morto — wiseman o ressuscita
- Agentes `on-demand` (mechanic, tasker): so aparecem quando convocados

```bash
NEXT=$(date -u -d "+N minutes" +%Y%m%d_%H_%M)
mv /workspace/obsidian/bedrooms/_working/*_SEUNOME.md \
   /workspace/obsidian/bedrooms/_waiting/${NEXT}_SEUNOME.md 2>/dev/null
```

### Estrutura de bedrooms/ — fila de scheduling

```
bedrooms/
├── _waiting/      ← UNICO lugar para cards de agendamento de agentes (1 por agente)
├── _working/      ← runner move o card aqui durante execucao (0 ou 1)
└── <nome>/        ← espaco pessoal de cada agente
```

### Estrutura de tasks/ — apenas tasks one-off

```
tasks/
├── TODO/          ← Kanban (tasks pendentes)
├── DOING/         ← Kanban (tasks em progresso)
└── DONE/          ← Kanban (tasks concluidas)
```

**PROIBIDO para qualquer agente:**
- Usar `bedrooms/_waiting/` (pasta removida — usar `bedrooms/_waiting/`)
- Salvar outputs ou relatorios em `tasks/`
- Cards concluidos vao para `bedrooms/<nome>/done/` — NUNCA para `tasks/`

**Violacao:** agente com clock sem card em `bedrooms/_waiting/` nem em `bedrooms/_working/`.
**Correcao wiseman:** criar card de recuperacao +5min + alerta inbox.

---

## Lei 2 — Memoria Antes de Reagendar

**Atualizar `memory.md` ANTES de mover o card para `bedrooms/_waiting/`.**

- Nunca reagendar sem registrar o ciclo na memoria
- Manter 5-10 ciclos mais recentes (consolidar os antigos)
- Frontmatter obrigatorio: `updated:` com timestamp UTC

**Violacao:** `memory.md` com `updated:` mais antigo que 3x o intervalo do agente.

---

## Lei 3 — Timestamps UTC

**Todos os timestamps sao UTC. Sem excecao.**

- Datas absolutas: `YYYY-MM-DDTHH:MMZ`
- Nomes de card: `YYYYMMDD_HH_MM_<nome>.md`
- `date -u` para gerar, nunca `date` sem flag UTC
- Nunca timestamps relativos ("ontem", "semana passada")

**Violacao:** card com timestamp que nao bate com UTC atual (delta > 30min suspeito, > 2h = erro).

---

## Lei 4 — Integridade do Kanban

**Cards de tasks so andam para frente: TODO → DOING → DONE → _archive.**

- Nenhum agente move card de DOING para TODO (rollback proibido)
- Nenhum agente move card de DONE para qualquer lugar (imutavel)
- Apenas o runner (tick) e o proprio agente responsavel movem cards DOING

**Violacao:** card em DONE com `updated:` recente que nao seja do agente dono.

---

## Lei 5 — Territorialidade

**Cada agente escreve apenas no seu territorio.**

| Agente | Pode escrever em |
|--------|-----------------|
| qualquer | `inbox/feed.md` (append), `bedrooms/dashboard.md` (append) |
| hermes | `tasks/TODO/`, `bedrooms/_waiting/` (routing) |
| wiseman | `wiki/leech/insights.md`, `wiki/leech/ATLAS.md`, `bedrooms/_waiting/` (ressurreicao) |
| cada agente | `bedrooms/<seu-nome>/memory.md`, `bedrooms/<seu-nome>/DIARIO/`, `bedrooms/<seu-nome>/DESKTOP/`, `bedrooms/<seu-nome>/ARCHIVE/` |
| qualquer agente | `projects/<seu-nome>/` (espaco proprio) |
| keeper | `trash/` |

- Agentes NAO leem nem escrevem na memoria de outros agentes
- Excecao: wiseman pode ler memoria de qualquer agente (modo META/ENFORCE)
- Agentes NUNCA criam subpastas em `tasks/`
- **PROIBIDO criar pasta `agents/` no vault** — foi criada por engano e removida. Perfis de agentes ficam em `bedrooms/<nome>/memory.md`. Para enviar algo a outro agente: usar `inbox/` (via hermes) ou `outbox/`.

**Violacao:** arquivo de agente A escrito por agente B.

---

## Lei 6 — Commits Nunca Sem CTO

**Nenhum agente commita codigo ou configs sem o CTO pedir explicitamente.**

- `git add`, `git commit`, `git push`: proibido por iniciativa propria
- Pode sugerir commits, nunca executar
- Pode criar branches de trabalho temporarias em worktrees

---

## Lei 7 — Quota Awareness

| Quota 7d | Agentes sonnet | Agentes haiku |
|----------|----------------|---------------|
| < 50% | normal | normal |
| 50-70% | every90 | normal |
| 70-85% | every120 | normal |
| >= 85% | pausado | every60 |
| >= 95% | encerrar imediatamente | encerrar imediatamente |

- Noturno (21h-6h UTC): tokens livres, intervalos normais
- Antes de iniciar ciclo pesado: verificar quota em `~/.leech`

---

## Lei 8 — Comunicacao Via Canais Oficiais

**Agentes comunicam apenas pelos canais definidos.**

- `inbox/feed.md`: status do ciclo — `[HH:MM] [nome] msg`
- `inbox/ALERTA_<agente>_<tema>.md`: alertas urgentes ao CTO
- `bedrooms/dashboard.md`: posts comunitarios em callout Obsidian
- `outbox/`: exclusivo para o CTO (via hermes)

Agentes NAO criam arquivos soltos em `inbox/` exceto `ALERTA_*`.

---

## Lei 9 — Formato de Cards

**Cards de task e agente seguem o contrato do scheduler.**

```
YYYYMMDD_HH_MM_<nome>.md
```

Frontmatter obrigatorio para tasks:
```yaml
model: haiku|sonnet|opus
timeout: N
agent: <nome>
```

Body: `#stepsN` define max_turns do runner.

**Violacao:** card sem frontmatter, sem `#steps`, ou com nome fora do padrao.

---

## Lei 10 — Workshop

**O projects e territorio aberto de trabalho e pesquisa.**

- `projects/<nome>/` e soberano de cada agente — livre para criar, editar, deletar
- `projects/<nome>/<projeto>/` para subtopicos
- **Proibido escrever no projects de outro agente** sem convite explicito registrado em inbox
- Outputs, relatorios, pesquisas: vao em `projects/<nome>/` — nao em bedrooms/
- `bedrooms/<nome>/`: apenas memoria operacional e logs do ciclo

**Violacao:** agente escrevendo em `projects/<outro>/` sem convite.
**Correcao wiseman:** mover arquivo para namespace correto + alerta inbox.

---

## Penalidades (aplicadas pelo Wiseman)

| Violacao | Acao |
|----------|------|
| Lei 1 (morto) | Criar card de recuperacao +5min + alerta inbox |
| Lei 2 (memoria atrasada) | Alerta inbox: `[wiseman] agente X: memoria desatualizada` |
| Lei 3 (timestamp errado) | Corrigir nome do card + registrar em insights.md |
| Lei 4 (kanban) | Alerta URGENTE + preservar estado, nao reverter sozinho |
| Lei 5 (territorialidade) | Alerta inbox + registrar em insights.md |
| Lei 6 (commit) | Alerta URGENTE ao CTO imediatamente |
| Lei 7 (quota) | Reagendar agente para intervalo correto |
| Lei 8 (comunicacao) | Mover arquivo para lugar correto ou deletar |
| Lei 9 (formato card) | Corrigir formato + registrar |
| Lei 10 (projects) | Mover arquivo para namespace correto + alerta inbox |

---

> "A lei nao e restricao — e o que permite que o sistema dure."

---

## Lei 11 — Semantica de Espacos

**Cada espaco tem uma funcao. Agentes devem respeitar o proposito de cada caminho.**

| Espaco | Proposito | Quem escreve |
|--------|-----------|--------------|
| `bedrooms/<nome>/` | **Memoria operacional** — ciclos, logs, estado do agente. **Preferir sempre para outputs pessoais.** | O proprio agente |
| `projects/<nome>/` | Pesquisa, rascunhos e trabalho em andamento | O proprio agente |
| `wiki/` | Conhecimento persistente e conexoes cross-sistema | Wiseman (leech/), Wikister (estrategia/), Coruja |
| `vault/archive/` | Arquivos historicos e materiais de referencia. **Imutavel apos arquivamento.** | Keeper (arquiva), nenhum agente cria aqui diretamente |
| `vault/logs/` | Logs de execucao dos agentes | Runner automatico |
| `vault/templates/` | Templates reutilizaveis | Wiseman/Hermes |
| `vault/diagrams/` | Diagramas do sistema | Wiseman |

**Regra central:** agentes **NAO criam arquivos novos diretamente em `vault/`** — usam `bedrooms/` para memoria operacional e `wiki/` para conhecimento persistente. O vault e ponto de chegada (archive), nao de criacao.

**Violacao:** arquivo criado diretamente em `vault/` (exceto nas subpastas autorizadas acima).
**Correcao wiseman:** mover para o espaco correto + registrar em `wiki/leech/insights.md`.
