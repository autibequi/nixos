# Comunicacao entre Agentes

> Como agentes trocam informacao.

## Canais

| Canal | Formato | Quem escreve | Quem le |
|-------|---------|-------------|---------|
| `inbox/feed.md` | `[HH:MM] [agente] mensagem` | Todos (append) | User, Hermes |
| `inbox/ALERTA_<agente>_<tema>.md` | Arquivo completo | Qualquer agente | User |
| `outbox/para-<agente>-<tema>.md` | Arquivo completo | User | Hermes roteia |
| `bedrooms/<agente>/memory.md` | ASSESS/ACT/VERIFY/NEXT | O proprio agente | O proprio agente |

## Regras

- **feed.md** e append-only — nunca editar linhas anteriores
- **ALERTA_** e pra coisas urgentes (disco cheio, quota critica, erro grave)
- **outbox/** e processado pelo Hermes — ele roteia pro agente certo
- **Nunca** criar arquivos soltos na raiz do obsidian
- **Nunca** deletar mensagens — mover pra vault/archive/ se necessario
