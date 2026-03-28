# Obsidian — Estrutura e Territorios

> Vault montado em `/workspace/obsidian/`

## Mapa

```
obsidian/
├── DASHBOARD.md      Kanban central (TODO/DOING/DONE/WAITING)
├── bedrooms/         Estado persistente dos agentes
│   └── <agente>/
│       ├── BRIEFING.md   O que fazer na ronda
│       └── memory.md     Memoria entre ciclos
├── projects/         Projetos com briefings
│   └── <projeto>/
│       ├── BRIEFING.md   Instrucoes pro agente
│       └── ...           Artefatos do projeto
├── memory/           Memoria cross-session (feedback, projetos, refs)
├── inbox/            Agentes → user
│   └── feed.md       Log unificado
├── outbox/           User → agentes
├── wiki/             Knowledge base
└── vault/            Arquivo permanente
    ├── insights.md   Blackboard compartilhado
    ├── logs/         agents.md, tasks.md
    ├── templates/    Templates de cards
    └── trash/        Cemiterio (preservado pra referencia)
```

## Territorios

| Agente | Pode escrever em |
|--------|-----------------|
| Qualquer | `bedrooms/<seu-nome>/` |
| Qualquer | `inbox/feed.md` (append) |
| Qualquer | `inbox/ALERTA_<seu-nome>_*.md` |
| Conforme card | `projects/<projeto atribuido>/` |
| Sage modo DOCUMENT | `wiki/` |
| Keeper | `vault/archive/` |

**PROIBIDO:** escrever no bedroom/projeto de outro agente sem convite.
