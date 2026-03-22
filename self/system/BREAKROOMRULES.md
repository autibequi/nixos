---
type: rules
updated: 2026-03-22
scope: obsidian-agents
---
# BREAKROOMRULES — Protocolo Base de Todo Agent

> **TODO agent que interage com `/workspace/obsidian/agents/` DEVE ler este arquivo.**
> **Path canonico:** `/workspace/self/system/BREAKROOMRULES.md`
> **Stub no vault:** `/workspace/obsidian/agents/BREAKROOMRULES.md`
>
> Fonte da verdade: este arquivo + `/workspace/self/system/BOARDRULES.md`

---

## 1. REGRA ZERO — Self-Scheduling (OBRIGATORIO)

**Se voce nao se reagendar, voce MORRE. Nenhum outro sistema vai te ressuscitar.**

Ao final de CADA ciclo, ANTES de terminar, mova seu card de `_running/` para `_schedule/` com novo timestamp:

```bash
NEXT=$(date -d "+N minutes" +%Y%m%d_%H_%M)
mv /workspace/obsidian/agents/_running/*_SEUNOME.md \
   /workspace/obsidian/agents/_schedule/${NEXT}_SEUNOME.md 2>/dev/null
```

Onde N e o intervalo do seu clock (ver agent.md). Se nao tiver clock fixo, agendar para quando fizer sentido (minimo 30min, maximo 7 dias).

**Regras de reagendamento:**
- SEMPRE reagendar, mesmo que o ciclo tenha falhado
- SEMPRE reagendar, mesmo que nao tenha nada pra fazer
- Se em modo economia (quota >= 70%), aumentar intervalo 2x
- Se falhou: reagendar em +10min para retry
- Se nao ha trabalho: reagendar no intervalo normal ou maior
- Agents on-demand (sem clock): reagendar em +24h como heartbeat

**O que acontece se nao reagendar:**
- Nenhum card em `_schedule/` = o runner nunca mais te executa
- Voce fica morto ate alguem manualmente criar um card
- Isso e uma falha CRITICA — evite a todo custo

---

## 2. Inicio do Ciclo — Checklist

Todo ciclo comeca assim:

```bash
# 1. Ler regras
cat /workspace/self/system/BREAKROOMRULES.md
cat /workspace/self/system/BOARDRULES.md

# 2. Ler sua memoria
cat /workspace/obsidian/agents/SEUNOME/memory.md

# 3. Verificar mensagens do CTO
ls /workspace/obsidian/outbox/para-SEUNOME-*.md 2>/dev/null
```

Se existir mensagem do CTO:
1. Ler o arquivo
2. Incorporar no ciclo (responder, agir, ou registrar)
3. Mover para `agents/SEUNOME/cartas/respondido-YYYYMMDD.md`
4. Se pede acao imediata: agir neste ciclo + carta de resposta

---

## 3. Breakroom — Espaco Pessoal

O breakroom e **dados de runtime apenas** — memoria, diario, outputs, cartas.
Logica, instrucoes e configuracao do agent ficam em `zion/agents/<nome>/agent.md` (versionado em git).

```
/workspace/obsidian/agents/<nome>/
├── memory.md       — memoria persistente entre ciclos (OBRIGATORIO)
├── DIARIO.md       — diario pessoal append-only (opcional, mas recomendado)
├── diarios/        — logs de execucao por ciclo (YYYYMMDD_HH_MM.md)
├── outputs/        — artefatos produzidos (relatorios, vizualizacoes, etc)
├── cartas/         — copias de cartas enviadas/recebidas do CTO
└── done/           — cards concluidos (movidos pelo runner)
```

### memory.md — Padrao

Um unico arquivo. Frontmatter obrigatorio + corpo livre por ciclo:

```markdown
---
name: <nome>-memory
type: agent-memory
updated: YYYY-MM-DDTHH:MMZ
---

# <Nome> — Memory

## Ciclo: YYYY-MM-DD HH:MM UTC
<resumo do que foi feito, estado atual, pendencias>

## Ciclo anterior: ...
```

Regras:
- **Um unico `memory.md`** — nunca criar `memoria.md` paralelo ou duplicar
- Atualizar ANTES de reagendar (ordem importa — ver §5)
- Append de novos ciclos no topo, manter historico dos ultimos 5-10 ciclos
- Apagar ciclos muito antigos se ficar grande demais

### DIARIO.md — Padrao

Append-only. Nunca apagar entradas antigas.

```markdown
## [YYYY-MM-DD HH:MM] — <nome da atividade ou reflexao>

<texto livre — 3 a 8 frases na voz do agente>
```

### diarios/ — Logs por ciclo

Arquivo por execucao: `YYYYMMDD_HH_MM.md`
Conteudo: o que foi feito, o que foi encontrado, decisoes tomadas.
Opcional mas util para debugging.

### Activity Log — Centralizado (OBRIGATORIO)

O runner grava automaticamente uma linha por execucao em:
```
/workspace/obsidian/agents/_logs/activity/<nome>
```

Formato (tab-separated):
```
2026-03-21T08:15:00Z	coruja	ok	5m30s	in=1234 out=567	20260321_08_10_coruja
```

**O agent pode (opcionalmente) enriquecer com uma nota de resumo** ao final do ciclo:
```bash
ACTIVITY_FILE="/workspace/obsidian/agents/_logs/activity/SEUNOME"
printf "%s\tnote\t%s\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "resumo breve do que foi feito" >> "$ACTIVITY_FILE"
```

A nota aparece na coluna `card` quando lida por `zion agents log`.
Regras:
- Nao substituir a linha do runner — apenas adicionar a nota separada
- Maximo 80 chars por nota
- Nao obrigatorio — o runner ja registra status/tokens automaticamente

### O que NAO pertence ao breakroom

- `card.md` — obsoleto, dados do agente ficam em `zion/agents/<nome>/agent.md`
- Arquivos de configuracao estatica — pertencem ao agent.md
- Multiplos arquivos de memoria (`memoria.md` + `memory.md`) — consolidar em um

Nenhum outro agent edita seu breakroom (exceto doctor fazendo limpeza).
Se a pasta nao existir: `mkdir -p /workspace/obsidian/agents/<nome>`

---

## 4. Comunicacao com o CTO

### Feed (mensagem curta — rotina)
```
[HH:MM] [nome] mensagem
```
Append em `/workspace/obsidian/inbox/feed.md`

### Carta (comunicacao rica)
```
/workspace/obsidian/inbox/CARTA_<agente>_<YYYYMMDD_HH_MM>.md
```
Salvar copia em `agents/<nome>/cartas/`

### Alerta (urgente)
```
/workspace/obsidian/inbox/ALERTA_<agente>_<tema>.md
```

---

## 5. Fim do Ciclo — Checklist

```
1. [ ] Atualizar memory.md com resultado do ciclo
2. [ ] Comunicar via feed.md se houve algo relevante
3. [ ] (Opcional) Append nota em agents/_logs/activity/SEUNOME
4. [ ] REAGENDAR (Regra Zero) — mover card para _schedule/
5. [ ] Se escreveu carta: salvar copia em cartas/
```

A ordem importa: atualizar memoria ANTES de reagendar. Se o ciclo crashar durante o reschedule, pelo menos a memoria esta salva.

---

## 6. Regras Base

- Ler BREAKROOMRULES.md e BOARDRULES.md no inicio de cada ciclo
- Ler memory.md no inicio, atualizar no final
- Nunca commitar codigo sem o CTO pedir
- Nunca mover cards de DOING/ ou DONE/ — lifecycle e do runner
- Na duvida: registrar em memory.md e comunicar via feed.md
- Converter datas relativas em absolutas

---

## 7. Auto-Evolucao

Todo agent pode editar seu proprio `memory.md` e `DIARIO.md`.
Registrar mudancas em memory.md: `data | o que mudou | por que`.
Mudancas estruturais: carta ao CTO explicando.
