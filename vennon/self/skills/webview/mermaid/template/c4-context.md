---
name: webview/mermaid/template/c4-context
description: Exemplo C4Context — contexto do sistema (Estrategia); referência para diagram.mmd / base.html.
---

# Exemplo — C4 Context (referência)

## Para que serve neste contexto

| Uso | Papel |
|-----|--------|
| **Referência / cópia** | **Nível 1 C4**: atores humanos, sistema central e sistemas externos (sem detalhe de containers). |
| **Relay** | Ver `skills/webview/SKILL.md`. |

## Definição (resumo)

**C4Context** usa `Person`, `System`, `System_Ext`, `Rel`, etc. Documentação: [C4 diagrams](https://mermaid.ai/open-source/syntax/c4.html).

## Diagrama de exemplo — Plataforma Estrategia (contexto)

```mermaid
%%{init: {'theme': 'dark'}}%%
C4Context
title Plataforma Estrategia — contexto (exemplo)

Person(aluno, "Aluno", "Estuda pela web")
Person(admin, "Operador / instrutor", "Gestão no backoffice")
System_Ext(email, "Provedor de e-mail", "Notificações transacionais")
System_Ext(pg, "Gateway de pagamento", "Cobrança (exemplo)")

System(plataforma, "Plataforma Estrategia", "Entrega de conteúdo, matrículas e operações")

Rel(aluno, plataforma, "HTTPS — área do aluno")
Rel(admin, plataforma, "HTTPS — administração")
Rel(plataforma, email, "Envia e-mails")
Rel(plataforma, pg, "Processa pagamentos")
```

## Colar no `base.html` / live

Interior do bloco → `diagram.mmd`.

## Pré-visualização pontual (opcional)

```bash
python3 /workspace/self/scripts/chrome-relay.py show /workspace/self/skills/webview/mermaid/template/c4-context.md
```

Ver `template/README.md`, `../styling-global.md`.
