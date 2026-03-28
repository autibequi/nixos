---
name: code
description: Análise de código da branch atual — diff interativo, objetos por camada, diagrama de fluxo, relatório consolidado, inspeção de qualidade. Roteamento por subcomando.
---

# /code — Análise de Código

```
/code diff           → árvore interativa de arquivos no Chrome
/code objects        → objetos modificados por camada
/code flows          → diagrama de fluxo no Chrome
/code report         → relatório consolidado da branch
/code inspect        → inspeção leve de qualidade
/code review         → review completo de PR (JIRA + escopo + fluxo + validação + veredito)
/code peer-reviews   → simula review dos 5 peers do monolito
/code gh-review      → review de PR via GitHub API (sem branch local)
/code github-evaluate → avaliar dev por histórico de PRs no GitHub
/code tdd           → TDD cycle (RED-GREEN-REFACTOR) no arquivo/função atual
/code debug         → debugging sistemático em 4 fases (reproduzir, hipóteses, isolar, verificar)
/code test          → plano de testes a partir do diff (cenários Happy/Sad/Weird com prioridade)
/code flutter       → knowledge-base do app doings (Dart/Flutter)
/code practices     → boas práticas — checklist automático no código atual
/code               → sem argumento: mostra este menu
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
| `gh-review` | **8. GH Review** |
| `github-evaluate` / `evaluate` | **9. GitHub Evaluate** |
| `tdd` | **10. TDD** |
| `debug` | **11. Debug** |
| `test` / `test-plan` | **12. Test Plan** |
| `flutter` | **13. Flutter** |
| `practices` / `goodpractices` | **14. Good Practices** |
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

---

## 10. TDD — Red-Green-Refactor

Ler `skills/code/tdd/SKILL.md` e seguir as instrucoes.

Resumo: ciclo TDD disciplinado — escrever teste que falha (RED), implementar minimo para passar (GREEN), refatorar sem quebrar (REFACTOR). Guia de mocking, estrutura de arquivo de teste, e anti-patterns.

---

## 11. Debug — Debugging Sistematico

Ler `skills/code/debug/SKILL.md` e seguir as instrucoes.

Resumo: 4 fases — reproduzir o problema, levantar hipoteses, isolar causa raiz, verificar fix. Inclui log de investigacao estruturado e anti-patterns de debug.

---

## 12. Test Plan — Plano de Testes

Ler `skills/code/test/plan/SKILL.md` e seguir as instrucoes.

Resumo: gera plano de testes a partir do diff atual — levanta services/structs afetados, cria cenarios Happy/Sad/Weird com tags e prioridade por criticidade.

---

## 13. Flutter — Knowledge-base do App Doings

Ler `skills/code/flutter/SKILL.md` e seguir as instrucoes.

Resumo: knowledge-base do app Dart/Flutter da Estrategia — padroes de estado, navegacao, componentes, servicos e convencoes especificas do projeto doings.

---

## 14. Good Practices — Boas Praticas

Ler `skills/code/goodpractices/SKILL.md` e seguir as instrucoes.

Resumo: checklist automatico de boas praticas aplicado ao codigo atual — nomenclatura, responsabilidade unica, error handling, testabilidade, legibilidade.

