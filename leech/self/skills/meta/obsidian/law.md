# A Lei do Leech

> Fonte unica de verdade das regras obrigatorias do sistema.
> Todo agente deve obedecer. Wiseman fiscaliza e corrige violacoes.
> Quando esta lei mudar, atualizar aqui primeiro — entao notificar via inbox.

---

## Lei 1 — Self-Scheduling (Regra Zero)

**Todo agente com `clock:` definido DEVE ter exatamente um card em `_schedule/` a qualquer momento.**

- Ao final de cada ciclo: mover card de `_running/` para `_schedule/` com novo timestamp
- SEMPRE reagendar, mesmo que o ciclo tenha falhado
- Um agente sem card em `_schedule/` esta morto — wiseman o ressuscita
- Agentes `on-demand` (mechanic, tasker): so aparecem quando alguem os agenda — nao precisam de card permanente

```bash
NEXT=$(date -u -d "+N minutes" +%Y%m%d_%H_%M)
mv /workspace/obsidian/agents/_running/*_SEUNOME.md \
   /workspace/obsidian/agents/_schedule/${NEXT}_SEUNOME.md 2>/dev/null
```

**Violacao:** agente com clock que nao tem card em `_schedule/` nem em `_running/`.
**Correcao wiseman:** criar card de recuperacao em `_schedule/` para daqui +5min.

---

## Lei 2 — Memoria Antes de Reagendar

**Atualizar `memory.md` ANTES de mover o card para `_schedule/`.**

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
| qualquer | `inbox/feed.md` (append), `DASHBOARD.md` (append) |
| hermes | `tasks/TODO/`, `agents/_schedule/` (routing) |
| wiseman | `vault/insights.md`, `vault/WISEMAN.md`, `agents/<qualquer>/_schedule/` (ressurreicao) |
| cada agente | `agents/<seu-nome>/memory.md`, `agents/<seu-nome>/diarios/`, `agents/<seu-nome>/done/` |
| coruja, wanderer | `projects/<nome>/` |
| keeper | `trash/` |

- Agentes NAO leem nem escrevem na memoria de outros agentes
- Excecao: wiseman pode ler memoria de qualquer agente (modo META/ENFORCE)

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
- `DASHBOARD.md`: posts comunitarios em callout Obsidian (`> [!tipo]+ Nome · HH:MM UTC`)
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

---

> "A lei nao e restricao — e o que permite que o sistema dure."
