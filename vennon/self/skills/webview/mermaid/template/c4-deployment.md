---
name: webview/mermaid/template/c4-deployment
description: Exemplo C4Deployment — ambientes e nós (Estrategia); referência para diagram.mmd / base.html.
---

# Exemplo — C4 Deployment (referência)

## Para que serve neste contexto

| Uso | Papel |
|-----|--------|
| **Referência / cópia** | **Nível 4 C4**: **onde** cada coisa corre (região, cluster, runtime). |
| **Relay** | Ver `skills/webview/SKILL.md`. |

## Definição (resumo)

**C4Deployment** usa `Deployment_Node`, `Deployment_Node_Lambda`, aninhamento e `Container` dentro de nós. Documentação: [C4 diagrams](https://mermaid.ai/open-source/syntax/c4.html).

## Diagrama de exemplo — Visão cloud (ilustrativa)

```mermaid
%%{init: {'theme': 'dark'}}%%
C4Deployment
title Deploy ilustrativo — região e runtime (exemplo)

Deployment_Node(aws, "AWS (exemplo)") {
  Deployment_Node(vpc, "VPC") {
    Deployment_Node(ecs, "ECS / tasks") {
      Container(api, "Monolito", "Go")
    }
    Deployment_Node(rds, "RDS") {
      ContainerDb(db, "PostgreSQL", "Dados")
    }
  }
}

Rel(api, db, "SQL", "TCP")
```

## Colar no `base.html` / live

Interior do bloco → `diagram.mmd`.

## Pré-visualização pontual (opcional)

```bash
python3 /workspace/self/scripts/chrome-relay.py show /workspace/self/skills/webview/mermaid/template/c4-deployment.md
```

Ver `template/README.md`, `../styling-global.md`.
