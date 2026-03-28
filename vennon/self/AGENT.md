# Leech — Regras de Agente

> Agentes sao entidades inertes. So existem quando Hermes despacha um card do DASHBOARD.

---

## DASHBOARD — Fonte da Verdade

`/workspace/obsidian/DASHBOARD.md` e o kanban central. Tudo e card.

### Colunas

| Coluna | Significado |
|--------|-------------|
| **TODO** | Cards aguardando dispatch |
| **DOING** | Cards em execucao |
| **DONE** | Cards concluidos |
| **WAITING** | Cards que precisam de atencao do usuario |

### Formato de Card

```
- [ ] **nome-da-task** #agente #modelo #everyXmin `briefing:path/BRIEFING.md`
```

- `#agente` — quem executa (sage, coruja, keeper, paperboy, placeholder)
- `#modelo` — haiku ou sonnet
- `#everyXmin` — recorrente (Hermes recria no TODO apos DONE)
- `briefing:path` — arquivo que o agente le antes de executar
- `last:ISO` — ultima execucao (pra cards recorrentes)

### Exemplos

```
- [ ] **sage-ronda** #sage #sonnet #every60min `briefing:bedrooms/sage/BRIEFING.md`
- [ ] **jonathas-ciclo** #placeholder #haiku #every30min `briefing:projects/jonathas/BRIEFING.md`
- [ ] **limpar-inbox** #keeper #haiku `briefing:bedrooms/keeper/BRIEFING.md`
```

---

## Fluxo

```
yaa tick → Hermes acorda
    │
    ▼
Le DASHBOARD.md → coluna TODO
    │
    ▼
Para cada card (max 3/ciclo):
    ├── Extrai #agente, #modelo, briefing:
    ├── Le o BRIEFING.md
    ├── Move TODO → DOING
    ├── Despacha subagente com briefing no prompt
    ├── Subagente executa e retorna
    ├── Move DOING → DONE
    └── Se #everyXmin: recria card no TODO com last: atualizado
```

---

## Regras

| # | Lei | Resumo |
|---|-----|--------|
| 1 | Tudo e card | Nenhum agente acorda sozinho — precisa de card no TODO |
| 2 | Memoria Antes | Atualizar memory.md ANTES de encerrar ciclo |
| 3 | Timestamps UTC | Todos em UTC (`date -u +%Y-%m-%dT%H:%MZ`) |
| 4 | Kanban Forward | Cards andam: TODO → DOING → DONE |
| 5 | Territorialidade | Escrever no proprio bedroom + projeto atribuido |
| 6 | Sem Commits | Nunca git commit/push sem CTO pedir |
| 7 | Quota Aware | >= 85% so haiku, >= 95% ninguem |
| 8 | Canais Oficiais | Comunicar via feed.md, ALERTA_, DASHBOARD |
| 9 | Briefing obrigatorio | Card sem briefing: agente le seu bedroom/BRIEFING.md |
| 10 | Bedroom soberano | bedrooms/<nome>/ e sagrado — nao invadir |

---

## Protocolo do Agente (quando despachado)

### 1. Ler contexto
```bash
cat /workspace/self/AGENT.md                    # estas regras
cat /workspace/obsidian/bedrooms/NOME/memory.md # contexto anterior
cat <briefing>                                  # o que fazer neste ciclo
```

### 2. Pensar (OBRIGATORIO haiku, recomendado todos)
```
ASSESS: <o que vou fazer>. Memory: <ja existe | novo>. Worth: <sim|nao>.
```

### 3. Executar
- Usar bedroom (`bedrooms/NOME/`) pra estado persistente
- Se for projeto: trabalhar em `projects/<projeto>/`
- Nao invadir territorio alheio

### 4. Finalizar
- VERIFY: listar artefatos, confirmar existencia
- Append memory.md:
```
## Ciclo YYYY-MM-DD HH:MM
ASSESS: <planejado>
ACT: <executado>
VERIFY: <artefatos>
NEXT: <sugestao pro proximo ciclo>
```

---

## Estrutura

```
obsidian/
├── DASHBOARD.md          ← cards (TODO/DOING/DONE/WAITING)
├── bedrooms/             ← estado persistente dos agentes
│   ├── hermes/
│   │   ├── BRIEFING.md
│   │   └── memory.md
│   ├── sage/
│   ├── coruja/
│   ├── keeper/
│   ├── paperboy/
│   └── placeholder/
├── projects/             ← projetos com briefings
│   └── jonathas/
│       ├── BRIEFING.md
│       └── ...
├── inbox/                ← agents → user
├── outbox/               ← user → agents
├── wiki/                 ← knowledge base
└── vault/                ← arquivo permanente
```

---

## Referencias

| Topico | Arquivo |
|--------|---------|
| Leis detalhadas | `self/skills/meta/rules/laws.md` |
| Estrutura dirs | `self/skills/meta/rules/map.md` |
| Espacos | `self/skills/meta/rules/spaces.md` |
