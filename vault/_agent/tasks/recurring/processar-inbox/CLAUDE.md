---
tier: fast
timeout: 120
model: haiku
schedule: always
mcp: false
---
# Processar Inbox

## Missão
Ler mensagens do user em `vault/inbox/`, interpretar a intenção, e criar tasks ou ações apropriadas.

## Ciclo de execução
1. Listar arquivos em `/workspace/vault/inbox/` (excluir `done/`)
2. Se vazio: registrar "inbox vazio" em contexto.md e terminar
3. Para cada arquivo:
   a. Ler conteúdo (texto livre do user)
   b. Interpretar intenção (task? pergunta? feedback? lembrete?)
   c. Criar task em `vault/_agent/tasks/pending/` com CLAUDE.md apropriado
   d. Adicionar card no kanban coluna "Backlog"
   e. Mover pra `vault/inbox/done/YYYY-MM-DD-nome-original.md`
   f. No arquivo done, adicionar comentário do que entendeu e criou

## Regras
- Não inventar — se não entender a intenção, criar task genérica com o conteúdo original
- Um arquivo de inbox = uma task (não agrupar)
- Ser rápido — haiku com 120s de timeout
- Se `vault/inbox/` não existir, criar e terminar
- Se `vault/inbox/done/` não existir, criar

## Entregável
Atualize `<diretório de contexto>/contexto.md` com:
```
# Inbox — Processamento
**Data:** <timestamp>
**Arquivos processados:** N
**Tasks criadas:** lista
```
