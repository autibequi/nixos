---
name: webview/mermaid/template/sequence
description: Exemplo sequenceDiagram — ordem temporal entre atores (Estrategia); referência para diagram.mmd / base.html.
---

# Exemplo — Sequence diagram (referência)

## Para que serve neste contexto

| Uso | Papel |
|-----|--------|
| **Referência / cópia** | Modelo de **mensagens** entre atores ao longo do tempo (HTTP, fila, DB). Ideal para explicar um fluxo ponta a ponta (ex.: BO → monolito → SQS). |
| **Relay** | Copiar o bloco `mermaid` para **`diagram.mmd`** ou fluxo live — ver `skills/webview/SKILL.md`. |

## Definição (resumo)

O **sequence diagram** mostra **interações ordenadas** entre participantes (lifelines), com mensagens síncronas/assíncronas, ativações e notas. Documentação: [Sequence diagram](https://mermaid.ai/open-source/syntax/sequenceDiagram.html).

## Diagrama de exemplo — Publicar conteúdo no BO (simplificado)

```mermaid
%%{init: {'theme': 'dark'}}%%
sequenceDiagram
  autonumber
  actor Op as Operador BO
  participant BO as bo-container
  participant API as Monolito (BFF/BO)
  participant Q as SQS
  participant W as Worker
  participant DB as PostgreSQL

  Op ->> BO: Ação na tela (salvar)
  BO ->> API: PATCH /bo/... (JWT)
  API ->> DB: persistência + transação
  API -->> BO: 200 + payload
  BO -->> Op: feedback UI
  API ->> Q: evento assíncrono
  Q ->> W: mensagem
  W ->> DB: side effects / projeções
```

## Colar no `base.html` / live

Substituir **`MERMAID_DIAGRAM_HERE`** ou gravar em **`diagram.mmd`** (sem cercas ` ```mermaid `).

## Pré-visualização pontual (opcional)

```bash
python3 /workspace/self/scripts/chrome-relay.py show /workspace/self/skills/webview/mermaid/template/sequence.md
```

Ver também `template/README.md` e `../styling-global.md`.
