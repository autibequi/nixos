---
name: webview/mermaid/template/c4-dynamic
description: Exemplo C4Dynamic — interações dinâmicas (Estrategia); referência para diagram.mmd / base.html.
---

# Exemplo — C4 Dynamic (referência)

## Para que serve neste contexto

| Uso | Papel |
|-----|--------|
| **Referência / cópia** | **Fluxo dinâmico** em notação C4: quem chama quem (parecido a sequence, vista C4). |
| **Relay** | `diagram.mmd` + live. |

## Definição (resumo)

**C4Dynamic** combina elementos C4 com **Rel** encadeados para cenários temporais. Documentação: [C4 diagrams](https://mermaid.ai/open-source/syntax/c4.html).

## Diagrama de exemplo — Leitura de conteúdo pelo aluno

```mermaid
%%{init: {'theme': 'dark'}}%%
C4Dynamic
title Fluxo — aluno abre aula (exemplo)

Person(aluno, "Aluno")
Container(fs, "front-student", "Nuxt")
Container(api, "Monolito", "Go")
ContainerDb(db, "PostgreSQL", "Dados")

Rel(aluno, fs, "GET página", "HTTPS")
Rel(fs, api, "GET /bff/...", "JSON")
Rel(api, db, "SELECT / regras", "SQL")
Rel(api, fs, "payload + permissões", "JSON")
Rel(fs, aluno, "renderiza UI", "HTML")
```

## Colar no `base.html` / live

Interior do bloco → `diagram.mmd`.

## Pré-visualização pontual (opcional)

```bash
python3 /workspace/self/scripts/chrome-relay.py show /workspace/self/skills/webview/mermaid/template/c4-dynamic.md
```

Ver `template/README.md`, `../styling-global.md`.
