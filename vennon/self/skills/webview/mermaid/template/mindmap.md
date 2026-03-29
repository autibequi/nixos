---
name: webview/mermaid/template/mindmap
description: Exemplo mindmap — mapa mental (Estrategia); referência para diagram.mmd / base.html.
---

# Exemplo — Mindmap (referência)

## Para que serve neste contexto

| Uso | Papel |
|-----|--------|
| **Referência / cópia** | **Hierarquia radial**: ecossistema, módulos do monolito, áreas do BO ou do aluno. |
| **Relay** | Ver `skills/webview/SKILL.md`. |

## Definição (resumo)

O **mindmap** organiza ideias a partir de um **nó raiz** com ramos aninhados. Documentação: [Mindmap](https://mermaid.ai/open-source/syntax/mindmap.html).

## Diagrama de exemplo — Plataforma Estrategia (visão macro)

```mermaid
%%{init: {'theme': 'dark'}}%%
mindmap
  root((Plataforma Estrategia))
    Monolito Go
      Handlers BO
      Handlers BFF aluno
      Workers SQS
      Repositórios / GORM
    bo-container
      Quasar
      Módulos admin
    front-student
      Nuxt 2
      Design system
    Dados
      PostgreSQL
      Filas AWS
```

## Colar no `base.html` / live

Interior do bloco → `diagram.mmd`.

## Pré-visualização pontual (opcional)

```bash
python3 /workspace/self/scripts/chrome-relay.py show /workspace/self/skills/webview/mermaid/template/mindmap.md
```

Ver `template/README.md`, `../styling-global.md`.
