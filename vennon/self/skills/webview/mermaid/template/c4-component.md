---
name: webview/mermaid/template/c4-component
description: Exemplo C4Component — componentes dentro do monolito (Estrategia); referência para diagram.mmd / base.html.
---

# Exemplo — C4 Component (referência)

## Para que serve neste contexto

| Uso | Papel |
|-----|--------|
| **Referência / cópia** | **Nível 3 C4**: **componentes** dentro de um container (ex.: camadas do monolito). |
| **Relay** | Ver `skills/webview/SKILL.md`. |

## Definição (resumo)

**C4Component** descreve **componentes** e relações no interior de um **container**. Documentação: [C4 diagrams](https://mermaid.ai/open-source/syntax/c4.html).

## Diagrama de exemplo — Monolito (camadas simplificadas)

```mermaid
%%{init: {'theme': 'dark'}}%%
C4Component
title Monolito Go — componentes (exemplo)

Container_Boundary(api, "Monolito — API e workers") {
  Component(h_bo, "Handlers BO", "Go", "Endpoints administrativos")
  Component(h_bff, "Handlers BFF aluno", "Go", "Endpoints do aluno")
  Component(svc, "Services", "Go", "Casos de uso e regras")
  Component(repo, "Repositories", "Go", "Acesso a dados GORM")
  Component(w, "Workers SQS", "Go", "Consumidores de fila")
}

Rel(h_bo, svc, "chama")
Rel(h_bff, svc, "chama")
Rel(svc, repo, "persistência")
Rel(w, svc, "orquestra jobs")
```

## Colar no `base.html` / live

Interior do bloco → `diagram.mmd`.

## Pré-visualização pontual (opcional)

```bash
python3 /workspace/self/scripts/chrome-relay.py show /workspace/self/skills/webview/mermaid/template/c4-component.md
```

Ver `template/README.md`, `../styling-global.md`.
