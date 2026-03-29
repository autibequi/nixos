---
name: webview/mermaid/template/c4-container
description: Exemplo C4Container — apps e containers (Estrategia); referência para diagram.mmd / base.html.
---

# Exemplo — C4 Container (referência)

## Para que serve neste contexto

| Uso | Papel |
|-----|--------|
| **Referência / cópia** | **Nível 2 C4**: **aplicações executáveis** (front-student, bo-container, monolito, DB, filas). |
| **Relay** | `diagram.mmd` + live. |

## Definição (resumo)

**C4Container** usa `Person`, `Container`, `ContainerDb`, `System_Ext`, `Rel`, `Container_Boundary`. Documentação: [C4 diagrams](https://mermaid.ai/open-source/syntax/c4.html).

## Diagrama de exemplo — Containers principais

```mermaid
%%{init: {'theme': 'dark'}}%%
C4Container
title Plataforma Estrategia — containers (exemplo)

Person(aluno, "Aluno", "Navega no browser")
Person(admin, "Operador BO", "Painel administrativo")

Container_Boundary(plat, "Plataforma") {
  Container(fs, "front-student", "Nuxt 2, Vue", "Experiência do aluno")
  Container(bo, "bo-container", "Vue 2, Quasar", "Backoffice")
  Container(api, "Monolito", "Go", "APIs BO/BFF, workers")
  ContainerDb(db, "PostgreSQL", "Dados relacionais")
  Container(q, "Filas SQS", "AWS", "Processamento assíncrono")
}

Rel(aluno, fs, "HTTPS", "JSON")
Rel(admin, bo, "HTTPS", "JSON")
Rel(fs, api, "HTTPS", "BFF aluno")
Rel(bo, api, "HTTPS", "API admin")
Rel(api, db, "TCP", "SQL")
Rel(api, q, "HTTPS", "mensagens")
```

## Colar no `base.html` / live

Interior do bloco → `diagram.mmd`.

## Pré-visualização pontual (opcional)

```bash
python3 /workspace/self/scripts/chrome-relay.py show /workspace/self/skills/webview/mermaid/template/c4-container.md
```

Ver `template/README.md`, `../styling-global.md`.
