---
name: estrategia
description: Skill composta da Estrategia — cobre monolito (Go), bo-container (Vue/Quasar), front-student (Nuxt) e orquestrador (coordenacao cross-repo). Indice principal: roteie para a sub-skill certa conforme o repo e a acao.
---

# Estrategia — Skill Composta

Skill indice. Carregue as sub-skills conforme o repo e a acao solicitada.

## Sub-skills por repo

| Repo | Path no projeto | Sub-skills disponiveis |
|---|---|---|
| **monolito** | `/home/claude/projects/estrategia/monolito` | go-migration, go-repository, go-service, go-handler, go-worker, go-test, go-inspector, make-feature |
| **bo-container** | `/home/claude/projects/estrategia/bo-container` | component, page, route, service, make-feature, inspector |
| **front-student** | `/home/claude/projects/estrategia/front-student` | component, page, route, service, make-feature, inspector |

## Orquestrador — coordenacao cross-repo

O orquestrador e a skill que organiza tudo: features que tocam multiplos repos, PRs, changelogs, recommits, retomada de contexto, review.

| Skill | Quando usar |
|---|---|
| `orquestrador/orquestrar-feature` | Feature nova que toca 2+ repos |
| `orquestrador/retomar-feature` | Voltar ao trabalho de sessao anterior |
| `orquestrador/review-pr` | Review de PR aberto |
| `orquestrador/pr-inspector` | Inspecao profunda de PR (Go + Vue checklists) |
| `orquestrador/changelog` | Gerar changelog de uma feature/release |
| `orquestrador/recommit` | Reorganizar/reescrever commits antes do PR |
| `orquestrador/refinar-bug` | Mapear bug antes de implementar fix |
| `orquestrador/doc-branch` | Documentar estado de uma branch |

## Skills cross-repo (ferramentas globais)

| Skill | Quando usar |
|---|---|
| `estrategia/glance` | Visao geral dos arquivos modificados nos 3 repos vs main |
| `estrategia/grafana` | Logs Loki/CloudWatch, dashboards, debug pos-deploy |
| `estrategia/jira` | Ler card Jira completo com custom fields |
| `estrategia/opensearch` | Queries no cluster OpenSearch sandbox |

## Deteccao de repo

1. cwd sob `/home/claude/projects/estrategia/<repo>/` → repo identificado
2. `git remote get-url origin` contem `estrategiahq/<repo>`
3. User menciona nome do repo → ver tabela acima

## Regras de git (todas as repos)

Ver `estrategia/REGISTRY.md` → secao **Git Flow — Branch vs Worktree**.

Resumo:
- Bug fix pontual (~1-3 arquivos) → branch simples: `git checkout -b FUK2-XXXXX/descricao`
- Feature/refactor multi-camada/migration → worktree isolado: `git worktree add -b FUK2-XXXXX/... ../repo-FUK2-XXXXX main`
- Nomenclatura obrigatoria: `FUK2-XXXXX/descricao-curta-em-kebab`

## Sandbox local

| Uso | URL |
|---|---|
| App (front) | `http://local.estrategia-sandbox.com.br` |
| Admin (BO) | `http://admin.local.estrategia-sandbox.com.br` |
| API (monolito) | `http://api.local.estrategia-sandbox.com.br` |
