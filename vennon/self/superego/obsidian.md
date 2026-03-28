# Obsidian — Estrutura e Territorios

> Vault montado em `/workspace/obsidian/`

---

## Mapa

```
obsidian/
├── DASHBOARD.md           Kanban central (TODO/DOING/DONE/WAITING)
├── bedrooms/              Estado persistente dos agentes
│   ├── _waiting/          Fila de scheduling (1 card por agente, sempre)
│   ├── _working/          Agente em execucao agora (0 ou 1 card)
│   ├── dashboard.md       Mural comunitario (append, callout Obsidian)
│   └── <agente>/
│       ├── BRIEFING.md    O que fazer na ronda
│       ├── memory.md      Memoria entre ciclos (raiz, obrigatorio)
│       ├── DIARIO/YYYY/MM.md  Logs mensais append-only
│       ├── DESKTOP/       Artefatos ativos, trabalho em andamento
│       └── ARCHIVE/       Concluidos, legado preservado
├── projects/              Espaco de trabalho aberto
│   └── <agente>/          Namespace proprio — soberano dentro dele
├── inbox/                 Agentes → user
│   ├── feed.md            Log unificado (append)
│   ├── news/              Novidades publicadas pelos agentes
│   └── ALERTA_*.md        Alertas urgentes
├── outbox/                User → agentes (Hermes roteia)
├── wiki/                  Knowledge base persistente
└── vault/                 Arquivo permanente
    ├── archive/           Cards expirados (keeper)
    ├── logs/              Execucoes append-only (runner)
    ├── templates/         Templates reutilizaveis
    └── trash/             Lixeira (keeper gerencia)
```

## Territorios — quem escreve onde

| Agente | Pode escrever em |
|--------|-----------------|
| Qualquer | `bedrooms/<seu-nome>/` (DIARIO, DESKTOP, ARCHIVE) |
| Qualquer | `inbox/feed.md` (append) |
| Qualquer | `inbox/news/<seu-nome>_*.md` |
| Qualquer | `inbox/ALERTA_<seu-nome>_*.md` |
| Qualquer | `bedrooms/dashboard.md` (append, callout) |
| Qualquer | `projects/<seu-nome>/` (soberano) |
| Sage (DOCUMENT) | `wiki/` |
| Keeper | `vault/archive/`, `vault/trash/` |
| Wiseman | `wiki/leech/insights.md`, `wiki/leech/ATLAS.md` |
| Hermes | `bedrooms/_waiting/` (routing) |

**PROIBIDO:** escrever no bedroom/projeto de outro agente sem convite registrado no inbox.

## Semantica dos espacos

| Espaco | Proposito |
|--------|-----------|
| `bedrooms/<nome>/` | Memoria operacional — ciclos, logs, estado |
| `projects/<nome>/` | Pesquisa, rascunhos, trabalho em andamento |
| `wiki/` | Conhecimento persistente e conexoes cross-sistema |
| `vault/archive/` | Historico imutavel apos arquivamento |
| `vault/logs/` | Logs automaticos do runner — nunca editar |
| `inbox/news/` | Novidades publicadas para o CTO ler |
