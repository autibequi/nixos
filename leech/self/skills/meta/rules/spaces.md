---
maintainer: wiseman
updated: 2026-03-23T16:00Z
---

# Regras por Espaco

Regras de uso para cada diretorio/espaco do vault.

---

## workshop/

`workshop/` e o espaco de trabalho aberto do sistema.

- Cada agente e soberano em `workshop/<seu-nome>/` — livre para criar, editar, deletar
- Estrutura sugerida: `workshop/<nome>/<projeto>/`
- Proibido escrever em `workshop/<outro>/` sem convite registrado no inbox
- Outputs, relatorios, pesquisas, analises → workshop. Memoria do ciclo → bedroom.
- Keeper pode arquivar workspaces inativos > 30 dias

---

## bedrooms/

Memoria operacional dos agentes.

```
bedrooms/<nome>/
  memory.md       estado persistente (atualizar ANTES de reagendar — Lei 2)
  diarios/        logs append-only por ciclo
  done/           cards concluidos pelo runner (historico, nao apagar)
  outputs/        artefatos internos do agente
```

- `DIRETRIZES.md`: wiseman atualiza durante ENFORCE — nao editar manualmente
- Outros agentes nao escrevem em `bedrooms/<outro>/` sem convite

---

## inbox/ e outbox/

**Outbox** (CTO → agentes): jogue aqui qualquer delegacao. Hermes roteia.
- Formato sugerido: `para-<nome>-<tema>.md` ou arquivo livre (hermes infere)

**Inbox** (agentes → CTO):

| Arquivo | Quem | Formato |
|---------|------|---------|
| `feed.md` | qualquer agente | `[HH:MM] [nome] msg` (append) |
| `ALERTA_<agente>_<tema>.md` | qualquer agente | alerta urgente |
| `newspaper_*.md` | paperboy | digest de noticias |

- Agentes NAO criam arquivos soltos em `inbox/` — apenas `feed.md` (append) e `ALERTA_*`
- `bedrooms/dashboard.md`: mural comunitario — append, callout Obsidian

---

## vault/

Conhecimento permanente e cross-agent.

| Arquivo | Quem escreve |
|---------|-------------|
| `insights.md` | wiseman (e agentes com insight genuino) |
| `WISEMAN.md` | wiseman exclusivamente |
| `logs/*.md` | runner e daemon — automatico, nunca manual |
| `templates/` | qualquer agente pode adicionar |

- Nao criar arquivos soltos em `vault/` — usar subpastas
- Logs sao append-only — nunca editar linhas existentes
- `.ephemeral/` e temporario — keeper pode limpar sem aviso

---

## trash/

Gerenciado pelo keeper.

- Arquivos < 3 dias: arquivar, nunca deletar direto
- Arquivos sem referencias: candidato a delete permanente
- Arquivos com referencias: restaurar com nota
- Na duvida: arquivar. Keeper e conservador.
