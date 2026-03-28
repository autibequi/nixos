---
name: hermes-outbox-routing
type: project
updated: 2026-03-23T00:20Z
---

# Hermes — Roteamento do Outbox

Hermes processa dois tipos de mensagens no outbox:

## Outbox Tagado (step 2)
Arquivos com prefixo `para-<agente>-*.md` — entregues diretamente ao destinatário explícito.

## Outbox Livre (step 2b) — adicionado 2026-03-23
Arquivos **sem** prefixo `para-` — Pedro escrevendo direto, sem nomear destinatário.

Lógica de roteamento por conteúdo:
- Monitoramento, alarme, métrica → `agents/coruja/cartas/`
- Task recorrente ou agente novo → `tasks/TODO/` + notificar inbox
- Ambíguo ou precisa confirmação → `inbox/[hermes-duvida]_<nome>.md`
- Após processar: deletar original do outbox

**Registro:** `[HH:MM] [hermes] outbox-livre: <arquivo> → <destino>` em `inbox/feed.md`

**Fonte:** `self/agents/hermes/agent.md` step 2b
