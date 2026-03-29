---
name: webview/mermaid/template/state
description: Exemplo stateDiagram-v2 — estados e transições (Estrategia); referência para diagram.mmd / base.html.
---

# Exemplo — State diagram (referência)

## Para que serve neste contexto

| Uso | Papel |
|-----|--------|
| **Referência / cópia** | **Máquinas de estado**: matrícula, pedido, job assíncrono, feature com estados claros. |
| **Relay** | `diagram.mmd` + live — ver `skills/webview/SKILL.md`. |

## Definição (resumo)

O **state diagram** modela **estados**, **transições**, eventuais **estados compostos** e histórico. Documentação: [State diagram](https://mermaid.ai/open-source/syntax/stateDiagram.html).

## Diagrama de exemplo — Acesso do aluno a um produto/conteúdo

```mermaid
%%{init: {'theme': 'dark'}}%%
stateDiagram-v2
  [*] --> Visitante
  Visitante --> Matriculado: compra / matrícula efetiva
  Matriculado --> EmProgresso: primeiro acesso ao conteúdo
  EmProgresso --> Concluido: critérios de conclusão
  EmProgresso --> Suspenso: política / inadimplência
  Suspenso --> EmProgresso: regularização
  Concluido --> [*]
  note right of Matriculado
    front-student consulta monolito
    para regras de liberação
  end note
```

## Colar no `base.html` / live

Conteúdo interno do bloco `mermaid` → `diagram.mmd` ou placeholder no HTML.

## Pré-visualização pontual (opcional)

```bash
python3 /workspace/self/scripts/chrome-relay.py show /workspace/self/skills/webview/mermaid/template/state.md
```

Ver `template/README.md`, `../styling-global.md`.
