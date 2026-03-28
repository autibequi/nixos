---
name: meta:self:superego
description: "Regras globais do sistema Leech — ativar sempre que tocar em: estrutura do vault, bedrooms, dashboard, cards, comunicacao entre agentes, scheduling, worktrees ou leis. Le e apresenta os arquivos de /workspace/self/superego/."
triggers:
  - "regras do sistema"
  - "leis dos agentes"
  - "estrutura do vault"
  - "briefing de agente"
  - "dashboard"
  - "formato de card"
  - "inbox outbox"
  - "bedroom"
  - "worktree"
  - "scheduling"
  - "comunicacao entre agentes"
  - "territories"
---

# Superego — Regras Globais do Sistema

> Fonte unica de verdade. Editar aqui = editar pra todos.

## Arquivos disponíveis

| Arquivo | Conteudo | Quando ler |
|---------|----------|------------|
| `leis.md` | Proibido, obrigatorio, penalidades | Sempre |
| `ciclo.md` | Boot → executar → finalizar → reagendar | Agentes em execucao |
| `dashboard.md` | Cards, tags, fluxo, quem pode editar | Tocar no DASHBOARD |
| `bedrooms.md` | DIARIO/DESKTOP/ARCHIVE, memory.md | Estrutura de quartos |
| `obsidian.md` | Mapa do vault, territorios | Qualquer duvida de onde escrever |
| `comunicacao.md` | Feed, news/, alertas, outbox | Comunicacao entre agentes |
| `worktrees.md` | Isolamento e aprovacao | Implementacao de codigo |

## Como usar esta skill

Ao ser ativado, ler o arquivo relevante ao topico em questao:

```bash
cat /workspace/self/superego/<arquivo>.md
```

Se o topico for amplo ou envolver multiplos arquivos, ler o README primeiro:

```bash
cat /workspace/self/superego/README.md
```

## Quando esta skill DEVE ser ativada

- User pergunta sobre regras, leis ou estrutura do sistema
- Antes de criar ou editar um BRIEFING.md
- Antes de adicionar card no DASHBOARD
- Qualquer duvida sobre onde um agente pode escrever
- Ao detectar possivel violacao de territorio
- Ao configurar nova ronda ou agente

## Caminho dos arquivos

```
/workspace/self/superego/
├── README.md
├── leis.md
├── ciclo.md
├── dashboard.md
├── bedrooms.md
├── obsidian.md
├── comunicacao.md
└── worktrees.md
```
