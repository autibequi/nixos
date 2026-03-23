# A Lei do Leech

> Fonte unica de verdade das regras obrigatorias do sistema.
> Todo agente deve obedecer. Wiseman fiscaliza e corrige violacoes.
> Quando esta lei mudar, atualizar aqui primeiro — entao notificar via inbox.

---

## Lei 1 — Self-Scheduling (Regra Zero)

**Todo agente com `clock:` definido DEVE ter exatamente um card em `tasks/AGENTS/` a qualquer momento.**

- Ao final de cada ciclo: mover card de `tasks/AGENTS/DOING/` para `tasks/AGENTS/` com novo timestamp
- SEMPRE reagendar, mesmo que o ciclo tenha falhado
- Um agente sem card em `tasks/AGENTS/` esta morto — wiseman o ressuscita
- Agentes `on-demand` (mechanic, tasker): so aparecem quando alguem os agenda — nao precisam de card permanente

```bash
NEXT=$(date -u -d "+N minutes" +%Y%m%d_%H_%M)
mv /workspace/obsidian/tasks/AGENTS/DOING/*_SEUNOME.md \
   /workspace/obsidian/tasks/AGENTS/${NEXT}_SEUNOME.md 2>/dev/null
```

### Estrutura de tasks/ — imutavel

```
tasks/
├── AGENTS/        ← UNICO lugar para cards de agendamento de agentes
│   └── DOING/     ← runner move o card aqui durante execucao
├── TODO/          ← Kanban humano (Pedro) — tasks pendentes
├── DOING/         ← Kanban humano (Pedro) — tasks em progresso
└── DONE/          ← Kanban humano (Pedro) — tasks concluidas
```

**PROIBIDO para qualquer agente:**
- Criar subpastas em `tasks/` (ex: `tasks/<nome>/`, `tasks/<nome>/done/`)
- Salvar outputs, relatorios ou qualquer dado em `tasks/`
- Cards concluidos vao para `bedrooms/<nome>/done/` — NUNCA para `tasks/<nome>/done/`

**Violacao:** agente com clock que nao tem card em `tasks/AGENTS/` nem em `tasks/AGENTS/DOING/`.
**Correcao wiseman:** criar card de recuperacao em `tasks/AGENTS/` para daqui +5min.
**Violacao (subpasta):** qualquer pasta em `tasks/` que nao seja AGENTS, TODO, DOING ou DONE.
**Correcao wiseman:** mover conteudo para `bedrooms/<agente>/done/` + deletar pasta + alerta inbox.

---

## Lei 2 — Memoria Antes de Reagendar

**Atualizar `memory.md` ANTES de mover o card para `tasks/AGENTS/`.**

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
| hermes | `tasks/TODO/`, `tasks/AGENTS/` (routing) |
| wiseman | `vault/insights.md`, `vault/WISEMAN.md`, `tasks/AGENTS/` (ressurreicao) |
| cada agente | `bedrooms/<seu-nome>/memory.md`, `bedrooms/<seu-nome>/diarios/`, `bedrooms/<seu-nome>/done/` |
| qualquer agente | `workshop/<seu-nome>/` (espaco proprio de trabalho) |
| keeper | `trash/` |

- Agentes NAO leem nem escrevem na memoria de outros agentes
- Excecao: wiseman pode ler memoria de qualquer agente (modo META/ENFORCE)
- **Agentes NUNCA criam subpastas em `tasks/`** — outputs e historicos de ciclo vao em `bedrooms/<nome>/done/`
- Dados que nao sao cards de agendamento nao pertencem a `tasks/` em nenhuma hipotese

**Violacao:** arquivo de memoria de agente A com `updated:` mais recente do que o ultimo ciclo do agente A.

---

## Lei 6 — Commits Nunca Sem CTO

**Nenhum agente commita codigo ou configs sem o CTO pedir explicitamente.**

- `git add`, `git commit`, `git push`: proibido por iniciativa propria
- Pode sugerir commits, nunca executar
- Pode criar branches de trabalho temporarias em worktrees

---

## Lei 7 — Quota Awareness

**Agentes respeitam a quota conforme escalonamento.**

| Quota 7d | Agentes sonnet | Agentes haiku |
|----------|----------------|---------------|
| < 50% | normal | normal |
| 50-70% | every90 | normal |
| 70-85% | every120 | normal |
| >= 85% | pausado | every60 |
| >= 95% | encerrar imediatamente | encerrar imediatamente |

- Noturno (21h-6h UTC): tokens livres, agentes podem usar intervalos normais
- Antes de iniciar ciclo pesado: verificar quota em `~/.leech`

---

## Lei 8 — Comunicacao Via Canais Oficiais

**Agentes comunicam apenas pelos canais definidos.**

- `inbox/feed.md`: mensagem de status do ciclo — formato `[HH:MM] [nome] msg`
- `inbox/ALERTA_<agente>_<tema>.md`: alertas urgentes para o CTO
- `bedrooms/dashboard.md`: posts comunitarios em callout Obsidian (`> [!tipo]+ Nome · HH:MM UTC`)
- `outbox/`: exclusivo para o CTO enviar mensagens para agentes (via hermes)

Agentes NAO criam arquivos soltos em `inbox/` exceto alertas com prefixo `ALERTA_`.

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

**O workshop e territorio aberto de trabalho e pesquisa.**

- `workshop/<nome>/` e o espaco proprio de cada agente — livre para criar, editar, deletar
- `workshop/<nome>/<projeto>/` para subtopicos (ex: `workshop/coruja/monolito/`)
- **Proibido escrever no workshop de outro agente** sem convite explicito registrado em inbox
- Outputs, relatorios, pesquisas, analises: tudo vai em `workshop/<nome>/` — nao em bedrooms/
- `bedrooms/<nome>/` e apenas para memoria operacional e logs do ciclo
- Conteudo compartilhado legado vive em `workshop/<topico>/` (sem namespace de agente)

**Violacao:** agente escrevendo em `workshop/<outro>/` sem convite.
**Correcao wiseman:** mover o arquivo para o namespace correto + alerta inbox.

---

## Penalidades (aplicadas pelo Wiseman)

| Violacao | Acao |
|----------|------|
| Lei 1 (morto) | Criar card de recuperacao +5min + alerta inbox |
| Lei 2 (memoria atrasada) | Alerta inbox: `[wiseman] agente X: memoria desatualizada` |
| Lei 3 (timestamp errado) | Corrigir nome do card + registrar em insights.md |
| Lei 4 (kanban) | Alerta URGENTE + preservar estado, nao reverter sozinho |
| Lei 5 (territorialidade) | Alerta inbox + registrar em insights.md |
| Lei 10 (workshop) | Mover arquivo para namespace correto + alerta inbox |
| Lei 6 (commit) | Alerta URGENTE ao CTO imediatamente |
| Lei 7 (quota) | Reagendar agente para intervalo correto |
| Lei 8 (comunicacao) | Mover arquivo para lugar correto ou deletar |
| Lei 9 (formato card) | Corrigir formato + registrar |

---

> "A lei nao e restricao — e o que permite que o sistema dure."
