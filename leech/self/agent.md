# Regras de Agente — Sistema Leech

> Este arquivo é a fonte da verdade para o comportamento de todos os agentes.
> Leia antes de qualquer ciclo. Sobrescreve regras conflitantes em outros arquivos.

---

## DASHBOARD — Fonte da Verdade

O arquivo `/workspace/obsidian/bedrooms/DASHBOARD.md` é o kanban central de gestão de agentes.
Todo agente tem um card lá. O Ticker garante isso.

### Colunas

| Coluna | Significado |
|--------|-------------|
| **SLEEPING** | Agente ocioso, aguardando próximo ciclo |
| **WORKING** | Agente em execução ativa |
| **DONE** | Agente sem tarefas no momento (não há nada a fazer) |
| **WAITING** | Agente quer mostrar algo ao usuário — aguarda atenção |

### Formato de Card

```
- [ ] **nome-do-agente** #modelo #schedule `last:2026-03-24T04:00Z`
```

- `#haiku` / `#sonnet` / `#opus` — modelo de execução
- `#ever10min` / `#ever20min` / `#ever30min` / `#ever60min` / `#everday` — frequência
- `#on-demand` — só roda quando explicitamente chamado (ticker não dispara)
- `` `last:TIMESTAMP` `` — última vez que o agente concluiu um ciclo (UTC)
- `` `started:TIMESTAMP` `` — quando o agente está em WORKING (substitui `last:`)

---

## Protocolo de Ciclo

### Ao Acordar (modo autônomo)

1. Ler `/workspace/obsidian/bedrooms/DASHBOARD.md`
2. Localizar seu card pelo nome
3. **Mover card de SLEEPING → WORKING** (substituir `last:` por `started:` com timestamp UTC agora)
4. Registrar início em `_logs/agents.md`:
   ```
   | 2026-03-24T22:14Z | nome | start |
   ```
5. Executar ciclo (ver `self/autonomous.md`)

### Ao Finalizar

1. **Mover card de WORKING → SLEEPING** (substituir `started:` por `last:` com timestamp UTC agora)
2. Registrar fim em `_logs/agents.md`:
   ```
   | 2026-03-24T22:16Z | nome | end | ok |
   ```
3. Atualizar `bedrooms/performance/` (Lei 11 — obrigatório)
4. Reagendar em `bedrooms/_waiting/` se aplicável

### Se Não Há Nada a Fazer

- Mover card para **DONE** com nota curta: `` `idle:2026-03-24T22:14Z` ``
- Ticker vai mover de volta para SLEEPING no próximo ciclo se houver schedule

### Para Mostrar Algo ao Usuário

- Mover card para **WAITING**
- Adicionar nota inline no card explicando o que quer mostrar
- Exemplo: `- [ ] **wanderer** #sonnet #ever60min `wants: análise de segurança pronta``
- Não encerrar até o usuário responder (ou timeout)

---

## Tags de Controle

Tags no card definem como o ticker e o executor se comportam:

| Tag | Efeito |
|-----|--------|
| `#haiku` | Executa como modelo haiku |
| `#sonnet` | Executa como modelo sonnet |
| `#opus` | Executa como modelo opus |
| `#ever10min` | Ticker dispara a cada 10min |
| `#ever20min` | Ticker dispara a cada 20min |
| `#ever30min` | Ticker dispara a cada 30min |
| `#ever60min` | Ticker dispara a cada 60min |
| `#everday` | Ticker dispara uma vez por dia |
| `#on-demand` | Ticker NÃO dispara — só roda via chamada explícita |
| `#stepsN` | Override de max_turns (ex: `#steps30`) |

---

## Leis Absolutas

1. **UTC sempre** — todos os timestamps em UTC (`date -u +%Y-%m-%dT%H:%MZ`)
2. **Sem commits** — nunca `git commit/push` sem CTO pedir explicitamente
3. **Territorialidade** — escrever apenas no próprio bedroom (`bedrooms/<nome>/`) e workspace (`workshop/<nome>/`)
4. **Quota** — `pct >= 85%`: sonnet pausa. `pct >= 95%`: todos encerram imediatamente
5. **Performance** — ao fim de todo ciclo: atualizar `bedrooms/performance/` com dados do boot
6. **Cards** — nunca deixar card em WORKING ao encerrar (mover para SLEEPING ou DONE)
7. **Canais** — comunicar via inbox, feed.md ou DASHBOARD (não criar arquivos soltos no raiz)

---

## Logs

### `bedrooms/_logs/agents.md`
Append-only. Cada agente registra início e fim:
```
| TIMESTAMP_UTC | nome | start |
| TIMESTAMP_UTC | nome | end | ok |
| TIMESTAMP_UTC | nome | end | erro: descrição |
```

### `bedrooms/_logs/ticker.md`
Gerenciado pelo ticker. Não escrever aqui diretamente.

### `bedrooms/performance/`
Obrigatório ao fim de cada ciclo (Lei 11). Ler `self/skills/meta/rules/laws.md` para detalhes.

---

## Referências

- Modo autônomo detalhado: `self/autonomous.md`
- Leis completas + penalidades: `self/skills/meta/rules/laws.md`
- Scheduling: `self/skills/meta/rules/scheduling.md`
- Estrutura de diretórios: `self/skills/meta/rules/map.md`
