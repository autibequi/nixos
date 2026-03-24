# Agentroom — Protocolo dos Agents

> **A Lei completa (10 leis + penalidades):** `self/skills/meta/rules/laws.md`
> Wiseman le e fiscaliza. Agentes sao responsaveis por conhecer a lei.

## Ativação — "FORAM ACIONADOS, COMECEM"

Ao ouvir este sinal (por qualquer canal), todo agente deve:

**1. Registrar presença em `_waiting/`** antes de qualquer outra ação:

```bash
echo "agent: SEUNOME\nactivated: $(date -u +%Y-%m-%dT%H:%MZ)\nstatus: iniciando" > \
  /workspace/obsidian/agents/_waiting/$(date -u +%Y%m%d_%H%M)_SEUNOME.md
```

**2. Executar o ciclo normal** conforme seu agent.md.

**3. Ao terminar**, remover o arquivo de `_waiting/` (ou mover para `_working/` se ainda em execução prolongada).

> `_waiting/` = presença anunciada mas ainda não rodando
> `_working/` = em execução ativa

---

## Regra Zero — Self-Scheduling

**Nao reagendar = morrer.** Ao final de CADA ciclo:

```bash
NEXT=$(date -u -d "+N minutes" +%Y%m%d_%H_%M)
mv /workspace/obsidian/tasks/AGENTS/DOING/*_SEUNOME.md \
   /workspace/obsidian/tasks/AGENTS/${NEXT}_SEUNOME.md 2>/dev/null
```

- SEMPRE reagendar, mesmo se falhar
- Quota >= 70%: intervalo 2x
- On-demand: +24h heartbeat

## tasks/AGENTS/ — Contrato do Scheduler

`tasks/AGENTS/` e a fila de execucao dos agentes. **Apenas agentes** — nenhuma task avulsa.

**Invariante obrigatoria:** todo agente com `clock:` definido em seu `agent.md` DEVE ter exatamente **um** card em `tasks/AGENTS/` a qualquer momento — mesmo que seja para daqui a 1 ano.

```
tasks/AGENTS/
├── YYYYMMDD_HH_MM_<nome-do-agente>.md   ← um por agente (aguardando)
└── DOING/
    └── YYYYMMDD_HH_MM_<nome>.md         ← em execucao agora
```

- Formato do nome: `YYYYMMDD_HH_MM_<nome>.md`
- Um card por agente — o proximo agendamento. Nao acumular multiplos.
- Agentes `on-demand` (mechanic, tasker): nao precisam de card permanente
- O scheduler (tick) ordena por timestamp e executa os vencidos

**Auto-agendamento correto:**
```bash
NEXT=$(date -u -d "+N minutes" +%Y%m%d_%H_%M)
mv /workspace/obsidian/tasks/AGENTS/DOING/*_SEUNOME.md \
   /workspace/obsidian/tasks/AGENTS/${NEXT}_SEUNOME.md 2>/dev/null
```

## Inicio do Ciclo

```bash
cat /workspace/obsidian/bedrooms/SEUNOME/memory.md
ls /workspace/obsidian/outbox/para-SEUNOME-*.md 2>/dev/null
```

## Bedroom (memoria e arquivos do agente)

```
bedrooms/<nome>/
├── memory.md       — persistente (unico arquivo, atualizar ANTES de reagendar)
├── DIARIO.md       — append-only
├── diarios/        — logs por ciclo
├── outputs/        — artefatos internos
├── cartas/         — copias CTO
└── done/           — cards concluidos
```

## memory.md

```yaml
---
name: <nome>-memory
type: agent-memory
updated: YYYY-MM-DDTHH:MMZ
---
```

Append ciclo novo no topo. Manter 5-10 ciclos.

## Workshop — Espaco de Trabalho Aberto

`/workspace/obsidian/workshop/` e o espaco de pesquisa e producao do sistema.

**Regras:**
- Qualquer agente pode ler e escrever em `workshop/<seu-nome>/`
- Cada agente tem sua pasta propria: `workshop/<nome>/`
- Subtopicos por pasta: `workshop/<nome>/<projeto>/`
- **Nao tocar no workshop de outro agente** sem convite explicito
- Conteudo compartilhado (legado): `workshop/<topico>/` (sem namespace de agente)

```
workshop/
├── coruja/           — pesquisa e segundo cerebro da coruja
│   ├── monolito/     — overview, patterns, hotspots, pulse
│   ├── bo-container/
│   └── front-student/
├── wanderer/         — exploracao e sintese
├── wiseman/          — grafo e weaving
├── jafar/            — reflexao e proposta
├── mechanic/         — auditorias e scans
├── assistant/        — monitoramento
├── hermes/           — logs de roteamento
├── keeper/           — relatorios de saude
├── paperboy/         — feeds e digests
├── tamagochi/        — diarios e cartas
├── tasker/           — estado de execucao de tasks
└── <topicos-legado>/ — monolito/, bo-container/, mortani/, etc.
```

## Fim do Ciclo

```
1. [ ] Atualizar memory.md
2. [ ] Append inbox/feed.md se relevante
3. [ ] Atualizar DIRETRIZES.md (sua secao)
4. [ ] Atualizar TOKENS.md com os % atuais do boot
5. [ ] REAGENDAR (Regra Zero)
```

### Passo 4 — Atualizar TOKENS.md

Obrigatorio ao fim de todo ciclo, inclusive sessoes interativas.

```bash
# Ler do bloco ---API_USAGE--- no boot:
#   5h: XX%  7d: XX%  ex: XX%
# Editar /workspace/obsidian/TOKENS.md:
#   - Substituir ultimo valor de cada line[] pelos % atuais
#   - Atualizar timestamp no topo
# Se virada de dia: adicionar DDm/DDn no x-axis + zeros nos arrays
```

Ver regras completas em `/workspace/obsidian/agents/performance/dashboard.md`.

### Passo 3 — Manter DIRETRIZES.md

Todo agente deve manter sua propria secao em `/workspace/obsidian/bedrooms/DIRETRIZES.md` atualizada.

**Quando atualizar:** sempre que houver mudanca no comportamento, regras ou territorio. Se nada mudou: pular.

**Como identificar sua secao:**
```bash
grep -n "^### SEUNOME" /workspace/obsidian/bedrooms/DIRETRIZES.md
```

**Regra:** nunca reescrever a secao inteira se so um detalhe mudou — editar cirurgicamente.

## Regras

- Nunca commitar sem CTO pedir
- Nunca mover cards DOING/DONE
- Datas absolutas, nunca relativas

## Criacao de cards com backlog de implementacao

**Antes de criar qualquer card que envolva implementacao de codigo ou feature:**

1. Carregar skill `refinar` (`/workspace/self/skills/thinking/refine/SKILL.md`)
2. Investigar o codebase alvo (ondas: estrutura → padroes → pontos de extensao)
3. Mapear camadas de dependencia
4. Montar backlog ordenado com tasks TX: dimensionadas para ~25min cada
5. So entao criar o card com o backlog embutido

**Regra de madrugada (21h-6h UTC):**
Cards de implementacao devem ser agendados para rodar na madrugada.
Ao criar um card pesado: `NEXT=$(date -u -d "tomorrow 02:00" +%Y%m%d_%H_%M)`.

**Sinal de que o backlog esta pronto:**
- Cada task tem resultado verificavel
- A ordem respeita as camadas (dados → estado → UI → polish)
- Nenhuma task tem mais de 3 arquivos novos
