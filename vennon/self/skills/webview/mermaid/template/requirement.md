---
name: webview/mermaid/template/requirement
description: Exemplo requirementDiagram — requisitos e rastreio (Estrategia); referência para diagram.mmd / base.html.
---

# Exemplo — Requirement diagram (referência)

## Para que serve neste contexto

| Uso | Papel |
|-----|--------|
| **Referência / cópia** | **Requisitos** (funcionais/NFR) ligados a **elementos** do sistema (caixa preta). |
| **Relay** | `diagram.mmd` + live. |

## Definição (resumo)

O **requirement diagram** liga **requisitos** a **elementos** com relações como *satisfies*, *verifies*. Documentação: [Requirement diagram](https://mermaid.ai/open-source/syntax/requirementDiagram.html).

## Diagrama de exemplo — NFR sobre API e filas

```mermaid
%%{init: {'theme': 'dark'}}%%
requirementDiagram

requirement r_latency {
  id: 1
  text: O monolito deve responder P95 abaixo de 500ms nos endpoints críticos do BFF aluno.
  risk: high
  verifymethod: test
}

requirement r_async {
  id: 2
  text: Processos longos devem ser deslocados para workers SQS sem bloquear request HTTP.
  risk: medium
  verifymethod: inspection
}

element monolith {
  type: system
  docref: repo monolito
}

element workers {
  type: system
  docref: pacote workers
}

monolith - satisfies -> r_latency
workers - satisfies -> r_async
```

## Colar no `base.html` / live

Interior do bloco → `diagram.mmd`.

## Pré-visualização pontual (opcional)

```bash
python3 /workspace/self/scripts/chrome-relay.py show /workspace/self/skills/webview/mermaid/template/requirement.md
```

Ver `template/README.md`, `../styling-global.md`.
