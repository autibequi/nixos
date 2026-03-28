---
name: coruja/orquestrador
description: "Skill composta do orquestrador — coordenacao cross-repo de features, PRs, changelogs, recommits e retomada de contexto. Carregar quando o trabalho envolve mais de 1 repo ou precisa de coordenacao."
---

# Orquestrador — Skill Composta

Skill indice do orquestrador. Coordena trabalho cross-repo entre monolito, bo-container e front-student.

## Sub-skills

| Sub-skill | Quando usar |
|---|---|
| `orquestrador/orquestrar-feature` | Feature nova que toca 2+ repos — ponto de entrada principal |
| `orquestrador/retomar-feature` | Voltar ao trabalho de sessao anterior (reconstroi contexto) |
| `orquestrador/review-pr` | Review de PR aberto |
| `orquestrador/pr-inspector` | Inspecao profunda de PR (Go + Vue checklists, black-box decomposition) |
| `orquestrador/changelog` | Gerar changelog de uma feature/release |
| `orquestrador/recommit` | Reorganizar/reescrever commits antes do PR |
| `orquestrador/refinar-bug` | Mapear bug antes de implementar fix (Jira + codebase) |
| `orquestrador/doc-branch` | Documentar estado de uma branch |
