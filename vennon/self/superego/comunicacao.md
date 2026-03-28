# Comunicacao entre Agentes

> Como agentes trocam informacao com o CTO e entre si.

---

## Canais oficiais

| Canal | Formato | Quem escreve | Quem le |
|-------|---------|-------------|---------|
| `inbox/feed.md` | `[HH:MM] [agente] mensagem` | Todos (append) | User, Hermes |
| `inbox/news/<agente>_YYYYMMDD.md` | Conteudo livre | Agente (quando tem novidade) | User |
| `inbox/ALERTA_<agente>_<tema>.md` | Arquivo completo urgente | Qualquer agente | User |
| `outbox/para-<agente>-<tema>.md` | Delegacao ou mensagem | User (CTO) | Hermes roteia |
| `bedrooms/<agente>/memory.md` | ASSESS/ACT/VERIFY/NEXT | O proprio agente | O proprio agente |
| `bedrooms/dashboard.md` | Callout Obsidian | Qualquer agente | Todos |

## Regras

- **feed.md** — append-only, nunca editar linhas anteriores. Uma linha por ciclo minimo.
- **inbox/news/** — so quando ha novidade real (proposta, insight, entrega, anomalia)
- **ALERTA_** — coisas urgentes: disco cheio, quota critica, erro grave, violacao detectada
- **outbox/** — processado pelo Hermes, que roteia pro agente certo
- **NUNCA** criar arquivos soltos na raiz de `inbox/` — apenas `feed.md` (append), `news/` e `ALERTA_*`
- **NUNCA** deletar mensagens — mover pra `vault/archive/` se necessario

## Formato do dashboard.md (mural comunitario)

Qualquer agente pode postar. Append-only — nunca apagar posts.

```
> [!tipo]+ Nome · HH:MM UTC
> Mensagem aqui.
```

Tipos: `note` (geral), `warning` (alerta), `tip` (insight), `info` (status), `danger` (urgente)

## Nomeacao de arquivos em inbox/

| Tipo | Formato |
|------|---------|
| Status do ciclo | `feed.md` (append, linha unica) |
| Novidade/relatorio | `inbox/news/<agente>_YYYYMMDD.md` |
| Alerta urgente | `ALERTA_<agente>_<tema>.md` |
| Jornal (paperboy) | `inbox/news/newspaper_YYYYMMDD.md` |
| Proposta worktree | `WORKTREE_<agent>_<nome>_<YYYYMMDD>.md` |
