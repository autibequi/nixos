# DASHBOARD — Como Funciona

> `/workspace/obsidian/DASHBOARD.md` e a unica fonte de verdade.
> Agentes sao inertes. So existem quando Hermes despacha um card.

## Colunas

| Coluna | Significado |
|--------|-------------|
| **TODO** | Cards aguardando dispatch |
| **DOING** | Cards em execucao (agente rodando) |
| **DONE** | Cards concluidos |
| **WAITING** | Cards que precisam de atencao do user |

## Formato de Card

```
- [ ] **nome** #agente #modelo #ronda #everyXmin `last:ISO` `briefing:path/BRIEFING.md`
```

### Tags obrigatorias

| Tag | Funcao |
|-----|--------|
| `#agente` | Quem executa (sage, coruja, keeper, paperboy, hefesto, venture) |
| `#haiku` / `#sonnet` / `#opus` | Modelo |
| `#ronda` | Card ciclico — SEMPRE volta pro TODO apos execucao |
| `#everyXmin` | Intervalo minimo entre execucoes (10, 30, 60, 120) |
| `briefing:path` | Arquivo que o agente le antes de executar (path relativo a /workspace/obsidian/) |
| `last:ISO` | Ultima execucao em UTC (Hermes compara com #everyXmin) |

### Regra #ronda

Cards com `#ronda` nunca ficam em DONE — voltam pro TODO com `last:` atualizado.
Cards sem `#ronda` sao one-off — ficam em DONE quando terminam.

## Quem pode editar o DASHBOARD

- **User (CTO):** pode adicionar, remover ou editar qualquer card
- **Hermes:** atualiza `last:` e move cards entre colunas
- **Outros agentes:** PROIBIDO editar o DASHBOARD diretamente — comunicar via outbox

## Como adicionar nova ronda

Somente o CTO adiciona cards novos. Formato minimo:

```
- [ ] **nome** #nome #modelo #ronda #everyXmin `last:2000-01-01T00:00Z` `briefing:bedrooms/nome/BRIEFING.md`
```

O `last:` inicial pode ser qualquer data passada — Hermes vai despachar na proxima tick.

## Fluxo

```
yaa tick
  → Hermes acorda
  → Le TODO
  → Para cada card vencido (last + interval < agora):
      → Le briefing
      → Move TODO → DOING
      → Despacha subagente
      → Recebe resultado
      → Move DOING → DONE
      → Se #ronda: recria no TODO com last: atualizado
```

## Hermes higieniza

ANTES e DEPOIS de cada ciclo:
- Cards em DOING sem agente rodando → volta pro TODO
- Cards duplicados → remove duplicata
- Cards #ronda em DONE sem copia no TODO → recria

## Constraints de agendamento (Hermes)

- Nunca criar card para agente sem `self/ego/<nome>/agent.md`
- Nunca agendar 2 agentes sonnet no mesmo slot de minuto
- Maximo 3 cards agendados por agente nas proximas 2h
- Nunca agendar sonnet quando quota >= 70% — apenas haiku
