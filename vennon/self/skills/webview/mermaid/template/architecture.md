---
name: webview/mermaid/template/architecture
description: Exemplo architecture-beta — serviços e grupos (Estrategia); referência para diagram.mmd / base.html.
---

# Exemplo — Architecture diagram (referência)

## Para que serve neste contexto

| Uso | Papel |
|-----|--------|
| **Referência / cópia** | **Mapa de serviços** com **grupos** (cloud), **ícones** e **arestas** direccionais (L/R/T/B). Requer Mermaid **v11.1+**. |
| **Relay** | Ver `skills/webview/SKILL.md`. |

## Definição (resumo)

**architecture-beta** usa `group`, `service`, `junction` e `edges` com sintaxe `serviço:L|R|T|B -- …`. Documentação: [Architecture](https://mermaid.ai/open-source/syntax/architecture.html).

## Diagrama de exemplo — Borda e núcleo

```mermaid
%%{init: {'theme': 'dark'}}%%
architecture-beta
group edge(cloud)[Borda — browsers]
group core(cloud)[Núcleo — backend]

service fs(server)[front-student] in edge
service bo(server)[bo-container] in edge
service api(server)[Monolito API] in core
service db(database)[PostgreSQL] in core
service q(disk)[SQS] in core

fs:R --> L:api
bo:R --> L:api
api:B --> T:db
api:R --> L:q
```

## Colar no `base.html` / live

Interior do bloco → `diagram.mmd`.

## Pré-visualização pontual (opcional)

```bash
python3 /workspace/self/scripts/chrome-relay.py show /workspace/self/skills/webview/mermaid/template/architecture.md
```

Ver `template/README.md`, `../styling-global.md`.
