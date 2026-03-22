---
name: code
description: Análise de código da branch atual — diff interativo, objetos por camada, diagrama de fluxo, relatório consolidado, inspeção de qualidade. Roteamento por subcomando.
---

# /code — Análise de Código

```
/code diff       → árvore interativa de arquivos no Chrome
/code objects    → objetos modificados por camada
/code flows      → diagrama de fluxo no Chrome
/code report     → relatório consolidado da branch
/code inspect    → inspeção leve de qualidade
/code review         → review completo de PR (JIRA + escopo + fluxo + validação + veredito)
/code peer-reviews   → simula review dos 5 peers do monolito (Washington, Pedro, Molina, Marquesini, William)
/code                → sem argumento: mostra este menu
```

---

## Roteamento

Parsear `$ARGUMENTS` (primeira palavra):

| Argumento | Skill |
|-----------|-------|
| `diff` | **1. Diff** |
| `objects` | **2. Objects** |
| `flows` | **3. Flows** |
| `report` | **4. Report** |
| `inspect` / `inspection` | **5. Inspect** |
| `review` | **6. Review** |
| `peer-reviews` / `peers` | **7. Peer Reviews** |
| vazio | Mostrar menu acima |

---

## 1. Diff — Árvore Interativa no Chrome

Ler `skills/code/analysis/diff/SKILL.md` e seguir as instruções.

Resumo: gera árvore interativa de diff (pastas colapsáveis, ancestor glow, copy path, path bar sticky) e abre no Chrome via relay. Tema Catppuccin Mocha dark.

**Entrada extra:** `$ARGUMENTS` após "diff" = repo ou branch específico.

---

## 2. Objects — Objetos por Camada

Ler `skills/code/analysis/objects/SKILL.md` e seguir as instruções.

Resumo: lista todos os objetos tocados na branch atual, categorizados por repo e camada (handlers, services, repos, workers, pages, components, etc.).

---

## 3. Flows — Diagrama de Fluxo no Chrome

Ler `skills/code/analysis/flows/SKILL.md` e seguir as instruções.

Resumo: gera diagrama Mermaid da arquitetura de fluxo da branch atual (read path + write path) e renderiza no Chrome com tema Catppuccin dark.

---

## 4. Report — Relatório Consolidado

Ler `skills/code/report/SKILL.md` e seguir as instruções.

Resumo: relatório completo da branch atual — objetos por camada + stats de adições/remoções + resumo narrativo em português. Pode salvar no Obsidian.

---

## 5. Inspect — Inspeção de Qualidade

Ler `skills/code/inspection/SKILL.md` e seguir as instruções.

Resumo: inspeção estática leve da branch atual — error handling, nil checks, contratos BFF/front, response shapes. Output com ✅ / ⚠️ / 🔴 por arquivo. Mais rápido que pr-inspector.

---

## 6. Review — Review Completo de PR

Ler `skills/code/review/SKILL.md` e seguir as instruções.

Resumo: pipeline automatico de review em 5 fases — contexto JIRA, escopo por camada, diagrama de fluxo ASCII, validacao de codigo, veredito final. Tudo inline no terminal, sem Chrome relay.

---

## 7. Peer Reviews — Simulacao dos 5 Peers

Ler `skills/code/peer-reviews/SKILL.md` e seguir as instruções.

Resumo: simula o olhar de 5 devs reais do monolito (Washington, Pedro Castro, Molina, Marquesini, William) sobre o diff atual. Cada um revisa com sua perspectiva e prioridades documentadas a partir de PRs reais. Maximo de cobertura de bugs antes de abrir PR.

Aceita `--dev washington|pedro|molina|marquesini|william` para rodar so uma perspectiva.
