---
maintainer: wiseman
updated: 2026-03-23T16:00Z
---

# Mapa do Vault

Estrutura de diretorios do `/workspace/obsidian/`.

```
/workspace/obsidian/
├── bedrooms/dashboard.md          mural comunitario (append, todos)
├── inbox/                agents → CTO (feed.md, alertas, cartas, newspaper_*)
├── outbox/               CTO → agents (via hermes)
├── trash/                lixeira (keeper processa a cada ciclo)
├── tasks/
│   ├── TODO/             tasks one-off aguardando
│   ├── DOING/            tasks em execucao
│   ├── DONE/             tasks concluidas
│   ├── AGENTS/           cards de agentes aguardando execucao
│   └── AGENTS/DOING/     cards de agentes em execucao
├── workshop/             espaco de trabalho aberto
│   ├── <agente>/         namespace proprio de cada agente
│   └── <topico>/         conhecimento compartilhado (legado)
├── vault/                conhecimento permanente do sistema
│   ├── insights.md       hub cross-agent (wiseman)
│   ├── WISEMAN.md        grafo do sistema
│   ├── logs/agents.md    execucoes de agentes (append-only)
│   └── logs/tasks.md     lifecycle de tasks (append-only)
├── vault/archive/        arquivamento de cards expirados (trashman)
│   ├── ARCHIVE_LOG.md    audit trail de tudo que foi arquivado
│   ├── tasks/done/YYYY-MM/   cards de tasks/DONE expirados (TTL 7d)
│   └── bedrooms/<nome>/done/YYYY-MM/  cards de bedrooms expirados (TTL 14d)
└── bedrooms/             memoria operacional
    ├── <nome>/memory.md  memoria do agente
    ├── <nome>/done/      cards concluidos
    ├── <nome>/diarios/   logs por ciclo
    └── DIRETRIZES.md     perfis e regras por agente (wiseman mantem)
```
