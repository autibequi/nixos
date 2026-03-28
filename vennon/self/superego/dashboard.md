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

### Tags

| Tag | Funcao |
|-----|--------|
| `#agente` | Quem executa (sage, coruja, keeper, paperboy, hefesto, venture) |
| `#haiku` / `#sonnet` / `#opus` | Modelo |
| `#ronda` | Card ciclico — SEMPRE volta pro TODO apos execucao |
| `#everyXmin` | Intervalo minimo entre execucoes (10, 30, 60, 120) |
| `briefing:path` | Arquivo que o agente le antes de executar |
| `last:ISO` | Ultima execucao (Hermes compara com #everyXmin) |

### Regra #ronda

Cards com `#ronda` nunca ficam em DONE — voltam pro TODO com `last:` atualizado.
Cards sem `#ronda` sao one-off — ficam em DONE quando terminam.

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
- Cards em DOING sem agente? → volta pro TODO
- Cards duplicados? → remove duplicata
- Cards #ronda em DONE sem copia no TODO? → recria
