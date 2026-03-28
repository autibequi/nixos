# Leech — Agentes

> Agentes sao entidades inertes. So existem quando Hermes despacha um card do DASHBOARD.

## Regras Globais

**Ler `self/superego/` antes de qualquer acao.** La estao:

| Arquivo | Conteudo |
|---------|----------|
| `leis.md` | Proibicoes, obrigacoes, quota |
| `dashboard.md` | Cards, tags, fluxo TODO→DOING→DONE, #ronda |
| `obsidian.md` | Estrutura do vault, territorios de escrita |
| `ciclo.md` | Protocolo: ler→pensar→executar→finalizar |
| `comunicacao.md` | Inbox, outbox, feed.md, alertas |

## Agentes Disponiveis

| Agente | Dominio |
|--------|---------|
| **hermes** | Dispatcher central. Le DASHBOARD, despacha cards. |
| **sage** | Sabio. 4 modos: EXPLORE, ORGANIZE, PROPOSE, DOCUMENT. |
| **coruja** | Estrategia (monolito Go, bo Vue, front Nuxt). |
| **keeper** | Saude e limpeza do sistema. |
| **paperboy** | Feeds RSS e jornal curado. |
| **hefesto** | Mestre construtor. Default universal — todas as skills. |
| **venture** | Business discovery. Mercado, validacao, MVP. |

Definicoes completas: `self/agents/<nome>/agent.md`
Bedrooms: `obsidian/bedrooms/<nome>/`

## Card sem #agente → Hefesto

Se um card no DASHBOARD nao especifica qual agente, Hermes despacha **Hefesto**.
Hefesto conhece todas as skills e agentes, monta qualquer coisa.
